import Foundation
import os

/// A new vocabulary word being introduced alongside a generated sentence.
///
/// Field convention matches the LLM payload from the Gemini schema:
/// `source` is the deck's *target* language (e.g. Ukrainian — the word as it
/// appears in the sentence); `target` is the deck's *source* language (e.g.
/// English — the translation the user reads to learn it).
public struct NewWord: Sendable, Equatable, Hashable {
    public let source: String
    public let target: String

    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }
}

public struct GeneratedSentence: Sendable, Equatable {
    public let source: String
    public let target: String
    public let newWords: [NewWord]

    public init(source: String, target: String, newWords: [NewWord] = []) {
        self.source = source
        self.target = target
        self.newWords = newWords
    }
}

public struct SentenceGenerationResult: Sendable, Equatable {
    public let sentences: [GeneratedSentence]

    public init(sentences: [GeneratedSentence]) {
        self.sentences = sentences
    }

    /// Deduplicated union of every `newWord` across every sentence in the result.
    /// Order matches first-occurrence as the sentences are scanned in order.
    public var newWords: [NewWord] {
        var seen = Set<String>()
        var out: [NewWord] = []
        for sentence in sentences {
            for word in sentence.newWords where seen.insert(word.source).inserted {
                out.append(word)
            }
        }
        return out
    }
}

public struct SentenceGenerator: Sendable {
    private let client: GeminiClient
    private let knownVocabulary: KnownVocabularyQuery
    private let recentSentences: RecentSentencesQuery
    private static let logger = Logger(subsystem: "com.recall.app", category: "SentenceGenerator")

    public init(
        client: GeminiClient,
        knownVocabulary: KnownVocabularyQuery,
        recentSentences: RecentSentencesQuery
    ) {
        self.client = client
        self.knownVocabulary = knownVocabulary
        self.recentSentences = recentSentences
    }

    public func generate(deck: Deck) async throws -> SentenceGenerationResult {
        let known: [KnownVocabularyQuery.Entry]
        let recent: [String]
        if let deckId = deck.id {
            known = (try? knownVocabulary.fetch(deckId: deckId)) ?? []
            recent = (try? recentSentences.fetch(deckId: deckId)) ?? []
        } else {
            known = []
            recent = []
        }

        let prompt = buildPrompt(deck: deck, known: known, recent: recent)
        let schema = try Self.responseSchemaData()
        let response = try await client.generate(prompt: prompt, responseSchema: schema)
        Self.logger.debug("Gemini response: \(response.text, privacy: .public)")
        let parsed = try parse(response.text)
        return try await applyDefensiveExtraction(to: parsed, deck: deck, known: known)
    }

    /// The LLM's `newWords` field is a hint, not ground truth. Tokenize each
    /// target sentence and diff against the known-vocab list plus the LLM's
    /// claimed new-words. Any leftover tokens are *leaked unknowns* — promote
    /// them to new-word entries so the bundled-insert path can persist them.
    ///
    /// Translation resolution choice: a single follow-up Gemini call. Re-uses
    /// the existing `GeminiClient` (no new collaborator), keeps the per-click
    /// cost negligible — only fires when something actually leaked.
    private func applyDefensiveExtraction(
        to result: SentenceGenerationResult,
        deck: Deck,
        known: [KnownVocabularyQuery.Entry]
    ) async throws -> SentenceGenerationResult {
        let knownTokens: Set<String> = Set(known.flatMap { entry in
            SentenceTokenizer.tokens(in: entry.target)
        })

        // Walk sentences once, collect leaked tokens per sentence in encounter order.
        var leakedPerSentence: [[String]] = []
        var allLeaked: [String] = []
        var seenLeaked = Set<String>()
        for sentence in result.sentences {
            let claimed = Set(sentence.newWords.flatMap { SentenceTokenizer.tokens(in: $0.source) })
            var leakedHere: [String] = []
            for token in SentenceTokenizer.tokens(in: sentence.target)
            where !knownTokens.contains(token) && !claimed.contains(token) {
                leakedHere.append(token)
                if seenLeaked.insert(token).inserted {
                    allLeaked.append(token)
                }
            }
            leakedPerSentence.append(leakedHere)
        }

        guard !allLeaked.isEmpty else { return result }

        let translations = try await resolveTranslations(
            for: allLeaked,
            sourceLanguage: deck.targetLanguage,
            targetLanguage: deck.sourceLanguage
        )

        let stitched = zip(result.sentences, leakedPerSentence).map { sentence, leaked -> GeneratedSentence in
            let extras = leaked.compactMap { token -> NewWord? in
                guard let translation = translations[token] else { return nil }
                return NewWord(source: token, target: translation)
            }
            return GeneratedSentence(
                source: sentence.source,
                target: sentence.target,
                newWords: sentence.newWords + extras
            )
        }
        return SentenceGenerationResult(sentences: stitched)
    }

    private func resolveTranslations(
        for words: [String],
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> [String: String] {
        let bulletList = words.map { "- \($0)" }.joined(separator: "\n")
        let prompt = """
        Translate each of the following \(sourceLanguage.displayName) words to \(targetLanguage.displayName).
        Respond as JSON matching the provided schema. Each translation entry's "source" is the input word, exactly as given; "target" is its \(targetLanguage.displayName) translation.

        Words:
        \(bulletList)
        """
        let schema = try Self.translationSchemaData()
        let response = try await client.generate(prompt: prompt, responseSchema: schema)
        guard let data = response.text.data(using: .utf8) else {
            throw GenerationError.malformedResponse
        }
        let decoded: TranslationPayload
        do {
            decoded = try JSONDecoder().decode(TranslationPayload.self, from: data)
        } catch {
            throw GenerationError.malformedResponse
        }
        var map: [String: String] = [:]
        for entry in decoded.translations {
            map[entry.source.lowercased()] = entry.target
        }
        return map
    }

    func buildPrompt(
        deck: Deck,
        known: [KnownVocabularyQuery.Entry],
        recent: [String]
    ) -> String {
        var prompt = """
        Generate 5 short, natural, conversational sentences in \(deck.targetLanguage.displayName).
        For each sentence, also provide its \(deck.sourceLanguage.displayName) translation.

        Keep sentences simple and useful for everyday speech.

        Compose sentences primarily from KNOWN VOCABULARY. Avoid sentences with meaning or structure near-identical to any in RECENTLY GENERATED. Variations with different vocabulary or different tense are fine.

        Introduce 0-2 new \(deck.targetLanguage.displayName) words per batch (max 3) — pick words that are easy to guess from cognates or context. For every new word you introduce, add an entry to that sentence's "newWords" list.

        Respond as JSON matching the provided schema:
        - "source" is the \(deck.sourceLanguage.displayName) translation.
        - "target" is the \(deck.targetLanguage.displayName) sentence.
        - "newWords" is an array of {source, target} objects. "source" is the new word in \(deck.targetLanguage.displayName); "target" is its \(deck.sourceLanguage.displayName) translation. Use an empty array if you do not introduce any new words in that sentence.

        """

        prompt += "\nKNOWN VOCABULARY:\n"
        if known.isEmpty {
            prompt += "(none yet)\n"
        } else {
            for entry in known {
                prompt += "- \(entry.target) — \(entry.source)\n"
            }
        }

        prompt += "\nRECENTLY GENERATED:\n"
        if recent.isEmpty {
            prompt += "(none yet)\n"
        } else {
            for sentence in recent {
                prompt += "- \(sentence)\n"
            }
        }

        return prompt
    }

    private func parse(_ json: String) throws -> SentenceGenerationResult {
        guard let data = json.data(using: .utf8) else {
            throw GenerationError.malformedResponse
        }
        let decoded: GeneratedPayload
        do {
            decoded = try JSONDecoder().decode(GeneratedPayload.self, from: data)
        } catch {
            throw GenerationError.malformedResponse
        }
        let sentences = decoded.sentences.map { payload in
            GeneratedSentence(
                source: payload.source,
                target: payload.target,
                newWords: (payload.newWords ?? []).map { NewWord(source: $0.source, target: $0.target) }
            )
        }
        return SentenceGenerationResult(sentences: sentences)
    }

    private static func responseSchemaData() throws -> Data {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "sentences": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "source": ["type": "string"],
                            "target": ["type": "string"],
                            "newWords": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "source": ["type": "string"],
                                        "target": ["type": "string"]
                                    ],
                                    "required": ["source", "target"]
                                ]
                            ]
                        ],
                        "required": ["source", "target", "newWords"]
                    ]
                ]
            ],
            "required": ["sentences"]
        ]
        return try JSONSerialization.data(withJSONObject: schema)
    }

    private static func translationSchemaData() throws -> Data {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "translations": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "source": ["type": "string"],
                            "target": ["type": "string"]
                        ],
                        "required": ["source", "target"]
                    ]
                ]
            ],
            "required": ["translations"]
        ]
        return try JSONSerialization.data(withJSONObject: schema)
    }

    public enum GenerationError: Error {
        case malformedResponse
    }
}

private struct GeneratedPayload: Decodable {
    let sentences: [GeneratedSentencePayload]
}

private struct GeneratedSentencePayload: Decodable {
    let source: String
    let target: String
    let newWords: [NewWordPayload]?
}

private struct NewWordPayload: Decodable {
    let source: String
    let target: String
}

private struct TranslationPayload: Decodable {
    let translations: [TranslationEntry]

    struct TranslationEntry: Decodable {
        let source: String
        let target: String
    }
}
