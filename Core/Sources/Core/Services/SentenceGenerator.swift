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
    private static let logger = Logger(subsystem: "com.recall.app", category: "SentenceGenerator")

    public init(client: GeminiClient) {
        self.client = client
    }

    public func generate(deck: Deck) async throws -> SentenceGenerationResult {
        let prompt = buildPrompt(deck: deck)
        let schema = try Self.responseSchemaData()
        let response = try await client.generate(prompt: prompt, responseSchema: schema)
        Self.logger.debug("Gemini response: \(response.text, privacy: .public)")
        return try parse(response.text)
    }

    private func buildPrompt(deck: Deck) -> String {
        """
        Generate 5 short, natural, conversational sentences in \(deck.targetLanguage.displayName).
        For each sentence, also provide its \(deck.sourceLanguage.displayName) translation.

        Keep sentences simple and useful for everyday speech. Avoid duplicates.

        Respond as JSON matching the provided schema:
        - "source" is the \(deck.sourceLanguage.displayName) translation.
        - "target" is the \(deck.targetLanguage.displayName) sentence.
        - "newWords" should be an empty array.
        """
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
