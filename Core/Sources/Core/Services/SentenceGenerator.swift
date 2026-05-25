import Foundation
import os

public struct GeneratedSentence: Sendable, Equatable {
    public let source: String
    public let target: String
    public let newWords: [String]

    public init(source: String, target: String, newWords: [String] = []) {
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
        return try parse(response.text)
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

        Respond as JSON matching the provided schema:
        - "source" is the \(deck.sourceLanguage.displayName) translation.
        - "target" is the \(deck.targetLanguage.displayName) sentence.
        - "newWords" should be an empty array.

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
        let sentences = decoded.sentences.map {
            GeneratedSentence(source: $0.source, target: $0.target, newWords: $0.newWords ?? [])
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
                                "items": ["type": "string"]
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
    let newWords: [String]?
}
