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

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Int = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
        return _value
    }
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

/// Seed `words` as word-cards with fsrsState >= 2 so they count as known vocabulary.
/// Each tuple is (target-language value, source-language value) — e.g. ("кава", "coffee").
private func seedKnownVocab(in db: DatabaseManager, deck: Deck, words: [(String, String)]) throws {
    let cardRepo = CardRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)
    for (target, source) in words {
        var card = Card(deckId: deck.id!, sourceValue: source, targetValue: target, kind: .word)
        try cardRepo.insert(&card)
        var p = try progressRepo.fetch(cardId: card.id!, direction: .sourceToTarget)!
        p.fsrsState = 2
        try progressRepo.update(&p)
    }
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
        // Seed known vocab for every token used in the canned sentences so
        // defensive extraction has nothing to chase and no follow-up call fires.
        try seedKnownVocab(in: db, deck: deck, words: [
            ("доброго", "good"), ("ранку", "morning"),
            ("як", "how"), ("справи", "are you"),
            ("дякую", "thank you"),
            ("до", "until"), ("завтра", "tomorrow"),
            ("я", "I"), ("люблю", "love"), ("каву", "coffee"),
        ])
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

    @Test func parsesNewWordsAsSourceTargetPairs() async throws {
        let canned = """
        {
          "sentences": [
            {
              "source": "I love coffee in the morning.",
              "target": "Я люблю каву вранці.",
              "newWords": [
                {"source": "каву", "target": "coffee"},
                {"source": "вранці", "target": "in the morning"}
              ]
            }
          ]
        }
        """
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: canned))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        // Seed known vocab so the leaked-unknown detector doesn't synthesize anything.
        try seedKnownVocab(in: db, deck: deck, words: [
            ("я", "I"), ("люблю", "love")
        ])
        let generator = makeGenerator(database: db, session: makeStubSession())

        let result = try await generator.generate(deck: deck)

        let first = try #require(result.sentences.first)
        #expect(first.newWords.count == 2)
        #expect(first.newWords.contains(NewWord(source: "каву", target: "coffee")))
        #expect(first.newWords.contains(NewWord(source: "вранці", target: "in the morning")))
        // Aggregated collection on the result is the union across sentences.
        #expect(result.newWords.count == 2)
    }

    @Test func defensivelyExtractsLeakedUnknownAndResolvesTranslation() async throws {
        // LLM claims no new words, but the target sentence contains "каву" which
        // is not in known vocab. Defensive pass should auto-promote it and
        // resolve its translation via a follow-up Gemini call.
        let sentenceJson = #"{"sentences":[{"source":"I love coffee.","target":"Я люблю каву.","newWords":[]}]}"#
        let translationJson = #"{"translations":[{"source":"каву","target":"coffee"}]}"#

        let counter = CallCounter()
        StubURLProtocol.requestHandler = { request in
            let calls = counter.next()
            let json = calls == 1 ? sentenceJson : translationJson
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: json))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        try seedKnownVocab(in: db, deck: deck, words: [("я", "I"), ("люблю", "love")])
        let generator = makeGenerator(database: db, session: makeStubSession())

        let result = try await generator.generate(deck: deck)

        let leaked = result.newWords.first { $0.source == "каву" }
        let extracted = try #require(leaked)
        #expect(extracted.target == "coffee")
        let firstSentence = try #require(result.sentences.first)
        #expect(firstSentence.newWords.contains(NewWord(source: "каву", target: "coffee")))
        #expect(counter.value == 2, "expected one sentence-gen call + one translation-resolution call")
    }

    @Test func doesNotReAddNewWordsAlreadyClaimedByLLM() async throws {
        // The LLM claims "каву" as a new word. Defensive pass should NOT re-add it.
        let sentenceJson = #"""
        {"sentences":[
          {"source":"I love coffee.","target":"Я люблю каву.","newWords":[{"source":"каву","target":"coffee"}]}
        ]}
        """#
        let counter = CallCounter()
        StubURLProtocol.requestHandler = { request in
            _ = counter.next()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: sentenceJson))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        try seedKnownVocab(in: db, deck: deck, words: [("я", "I"), ("люблю", "love")])
        let generator = makeGenerator(database: db, session: makeStubSession())

        let result = try await generator.generate(deck: deck)

        let kavuOccurrences = result.newWords.filter { $0.source == "каву" }
        #expect(kavuOccurrences.count == 1)
        #expect(kavuOccurrences.first?.target == "coffee")
        #expect(counter.value == 1, "no follow-up translation call needed when LLM listed all new words")
    }

    @Test func doesNotPromoteKnownVocabularyWordsAsNew() async throws {
        // Sentence uses only known vocab — no leaked words should be auto-promoted.
        let sentenceJson = #"""
        {"sentences":[
          {"source":"I love.","target":"Я люблю.","newWords":[]}
        ]}
        """#
        let counter = CallCounter()
        StubURLProtocol.requestHandler = { request in
            _ = counter.next()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: sentenceJson))
        }
        let db = try DatabaseManager.inMemory()
        let deck = try insertTestDeck(in: db)
        try seedKnownVocab(in: db, deck: deck, words: [("я", "I"), ("люблю", "love")])
        let generator = makeGenerator(database: db, session: makeStubSession())

        let result = try await generator.generate(deck: deck)

        #expect(result.newWords.isEmpty)
        #expect(counter.value == 1, "no follow-up call should be made when nothing leaked")
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
