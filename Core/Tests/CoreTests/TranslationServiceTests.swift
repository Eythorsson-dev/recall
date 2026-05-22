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

// .serialized prevents concurrent access to the shared StubURLProtocol.requestHandler static.
@Suite(.serialized)
struct TranslationServiceTests {
    @Test func translatesSuccessfully() async throws {
        StubURLProtocol.requestHandler = { _ in
            let data = #"{"data":{"translations":[{"translatedText":"Hei verden"}]}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: URL(string: "https://translation.googleapis.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        let service = TranslationService(apiKey: "test-key", session: makeStubSession())
        let result = try await service.translate("Hello world", from: .english, to: .norwegian)
        #expect(result == "Hei verden")
    }

    @Test func translationRequestIncludesApiKey() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let data = #"{"data":{"translations":[{"translatedText":"Hei"}]}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        let service = TranslationService(apiKey: "my-secret-key", session: makeStubSession())
        _ = try await service.translate("Hello", from: .english, to: .norwegian)
        #expect(capturedRequest?.url?.query?.contains("key=my-secret-key") == true)
    }

    @Test func throwsHttpErrorOnNon200Response() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let service = TranslationService(apiKey: "bad-key", session: makeStubSession())
        await #expect(throws: TranslationService.TranslationError.httpError(statusCode: 403)) {
            try await service.translate("Hello", from: .english, to: .norwegian)
        }
    }

    @Test func throwsMalformedResponseOnInvalidJSON() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }
        let service = TranslationService(apiKey: "test-key", session: makeStubSession())
        await #expect(throws: TranslationService.TranslationError.malformedResponse) {
            try await service.translate("Hello", from: .english, to: .norwegian)
        }
    }

    @Test func throwsMalformedResponseOnEmptyTranslations() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"data":{"translations":[]}}"#.data(using: .utf8)!)
        }
        let service = TranslationService(apiKey: "test-key", session: makeStubSession())
        await #expect(throws: TranslationService.TranslationError.malformedResponse) {
            try await service.translate("Hello", from: .english, to: .norwegian)
        }
    }
}

@Test func newCardDefaultsTargetValueIsUserModifiedToFalse() {
    let card = Card(deckId: 1, sourceValue: "test", targetValue: "test")
    #expect(card.targetValueIsUserModified == false)
}

@Test func v7MigrationExistingRowsDefaultToUserModified() throws {
    let db = try DatabaseManager.inMemory()
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try DeckRepository(database: db).insert(&deck)

    // Insert via raw SQL omitting targetValueIsUserModified — simulates pre-v6 rows during migration.
    try db.writer.write { dbConn in
        try dbConn.execute(
            sql: "INSERT INTO card (deckId, sourceValue, targetValue, createdAt, updatedAt) VALUES (?, 'привіт', 'hello', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
            arguments: [deck.id!]
        )
    }
    let cards = try db.reader.read { try Card.fetchAll($0) }
    #expect(cards[0].targetValueIsUserModified == true)
}
