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
        let client = GeminiClient(apiKey: "k", session: makeStubSession())
        let generator = SentenceGenerator(client: client)
        let deck = Deck(name: "Ukrainian", sourceLanguage: .english, targetLanguage: .ukrainian)

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
        let client = GeminiClient(apiKey: "k", session: makeStubSession())
        let generator = SentenceGenerator(client: client)
        let deck = Deck(name: "NO", sourceLanguage: .english, targetLanguage: .norwegian)

        _ = try await generator.generate(deck: deck)

        let body = try #require(capturedBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(json["contents"] as? [[String: Any]])
        let parts = try #require(contents.first?["parts"] as? [[String: Any]])
        let prompt = try #require(parts.first?["text"] as? String)
        #expect(prompt.contains("Norwegian"))
        #expect(prompt.contains("English"))
    }

    @Test func throwsOnMalformedSentencesJson() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, cannedGeminiResponse(jsonText: "not a valid sentences payload"))
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())
        let generator = SentenceGenerator(client: client)
        let deck = Deck(name: "UK", sourceLanguage: .english, targetLanguage: .ukrainian)

        var caughtMalformed = false
        do {
            _ = try await generator.generate(deck: deck)
        } catch SentenceGenerator.GenerationError.malformedResponse {
            caughtMalformed = true
        }
        #expect(caughtMalformed)
    }
}
