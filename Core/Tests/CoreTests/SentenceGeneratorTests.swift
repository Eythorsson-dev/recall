import Testing
import Foundation
@testable import Core

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeStubSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: config)
}

private func cannedGeminiResponse(jsonText: String) -> Data {
    let payload: [String: Any] = [
        "candidates": [
            [
                "content": [
                    "parts": [["text": jsonText]]
                ]
            ]
        ]
    ]
    return try! JSONSerialization.data(withJSONObject: payload)
}

private func readRequestBody(_ request: URLRequest) -> Data? {
    if let body = request.httpBody { return body }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }
    var data = Data()
    let bufferSize = 4096
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }
    while stream.hasBytesAvailable {
        let read = stream.read(buffer, maxLength: bufferSize)
        if read <= 0 { break }
        data.append(buffer, count: read)
    }
    return data
}

private func makeGenerator(database: DatabaseManager, session: URLSession) -> SentenceGenerator {
    SentenceGenerator(
        client: GeminiClient(apiKey: "k", session: session),
        knownVocabulary: KnownVocabularyQuery(database: database),
        recentSentences: RecentSentencesQuery(database: database)
    )
}

private func insertTestDeck(in db: DatabaseManager, source: Language = .english, target: Language = .ukrainian) throws -> Deck {
    var deck = Deck(name: "Test", sourceLanguage: source, targetLanguage: target)
    try DeckRepository(database: db).insert(&deck)
    return deck
}

private func capturedPromptText(from body: Data) throws -> String {
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    let contents = try #require(json["contents"] as? [[String: Any]])
    let parts = try #require(contents.first?["parts"] as? [[String: Any]])
    return try #require(parts.first?["text"] as? String)
}

@Suite(.serialized)
struct SentenceGeneratorTests {
    @Test func generatesFiveSentencesFromCannedResponse() async throws {
        let canned = """
        {
          "sentences": [
            {"source": "Good morning.", "target": "Доброго ранку.", "newWords": []},
            {"source": "How are you?", "target": "Як справи?", "newWords": []},
            {"source": "Thank you.", "target": "Дякую.", "newWords": []},
            {"source": "See you tomorrow.", "target": "До завтра.", "newWords": []},
            {"source": "I love coffee.", "target": "Я люблю каву.", "newWords": []}
          ]
        }
        """
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: canned))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        let generator = makeGenerator(database: db, session: makeStubSession())

        let result = try await generator.generate(deck: deck)

        #expect(result.sentences.count == 5)
        #expect(result.sentences.first?.source == "Good morning.")
        #expect(result.sentences.first?.target == "Доброго ранку.")
        #expect(result.sentences.allSatisfy { $0.newWords.isEmpty })
    }

    @Test func promptReferencesBothDeckLanguages() async throws {
        var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            capturedBody = readRequestBody(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: #"{"sentences":[]}"#))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db, source: .english, target: .norwegian)
        let generator = makeGenerator(database: db, session: makeStubSession())

        _ = try await generator.generate(deck: deck)

        let body = try #require(capturedBody)
        let prompt = try capturedPromptText(from: body)
        #expect(prompt.contains("Norwegian"))
        #expect(prompt.contains("English"))
    }

    @Test func throwsOnMalformedSentencesJson() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: "not a valid sentences payload"))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        let generator = makeGenerator(database: db, session: makeStubSession())

        var caughtMalformed = false
        do {
            _ = try await generator.generate(deck: deck)
        } catch SentenceGenerator.GenerationError.malformedResponse {
            caughtMalformed = true
        }
        #expect(caughtMalformed)
    }

    @Test func promptIncludesKnownVocabularyFromDatabase() async throws {
        var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            capturedBody = readRequestBody(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: #"{"sentences":[]}"#))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)

        // Two learned words and one not-yet-learned word
        let cardRepo = CardRepository(database: db)
        let progressRepo = CardProgressRepository(database: db)

        var learned1 = Card(deckId: deck.id!, sourceValue: "coffee", targetValue: "кава", kind: .word)
        var learned2 = Card(deckId: deck.id!, sourceValue: "thank you", targetValue: "дякую", kind: .word)
        var fresh = Card(deckId: deck.id!, sourceValue: "morning", targetValue: "ранок", kind: .word)
        try cardRepo.insert(&learned1)
        try cardRepo.insert(&learned2)
        try cardRepo.insert(&fresh)

        for cardId in [learned1.id!, learned2.id!] {
            var p = try progressRepo.fetch(cardId: cardId, direction: .sourceToTarget)!
            p.fsrsState = 2
            try progressRepo.update(&p)
        }

        let generator = makeGenerator(database: db, session: makeStubSession())
        _ = try await generator.generate(deck: deck)

        let body = try #require(capturedBody)
        let prompt = try capturedPromptText(from: body)
        #expect(prompt.contains("KNOWN VOCABULARY"))
        #expect(prompt.contains("кава"))
        #expect(prompt.contains("coffee"))
        #expect(prompt.contains("дякую"))
        #expect(!prompt.contains("ранок"))
    }

    @Test func promptIncludesRecentlyGeneratedFromDatabase() async throws {
        var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            capturedBody = readRequestBody(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: #"{"sentences":[]}"#))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        let cardRepo = CardRepository(database: db)

        var s1 = Card(
            deckId: deck.id!,
            sourceValue: "I love coffee.",
            targetValue: "Я люблю каву.",
            kind: .sentence
        )
        var s2 = Card(
            deckId: deck.id!,
            sourceValue: "Good morning.",
            targetValue: "Доброго ранку.",
            kind: .sentence
        )
        try cardRepo.insert(&s1)
        try cardRepo.insert(&s2)

        let generator = makeGenerator(database: db, session: makeStubSession())
        _ = try await generator.generate(deck: deck)

        let body = try #require(capturedBody)
        let prompt = try capturedPromptText(from: body)
        #expect(prompt.contains("RECENTLY GENERATED"))
        #expect(prompt.contains("Я люблю каву."))
        #expect(prompt.contains("Доброго ранку."))
    }

    @Test func promptIncludesDedupInstruction() async throws {
        var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            capturedBody = readRequestBody(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: #"{"sentences":[]}"#))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        let generator = makeGenerator(database: db, session: makeStubSession())

        _ = try await generator.generate(deck: deck)

        let body = try #require(capturedBody)
        let prompt = try capturedPromptText(from: body)
        #expect(prompt.contains("primarily from KNOWN VOCABULARY"))
        #expect(prompt.contains("RECENTLY GENERATED"))
        #expect(prompt.lowercased().contains("avoid"))
    }
}
