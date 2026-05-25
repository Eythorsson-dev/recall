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

private func minimalSchema() -> Data {
    let dict: [String: Any] = [
        "type": "object",
        "properties": ["foo": ["type": "string"]],
        "required": ["foo"]
    ]
    return try! JSONSerialization.data(withJSONObject: dict)
}

private func candidatesResponse(text: String) -> Data {
    let payload: [String: Any] = [
        "candidates": [
            [
                "content": [
                    "parts": [["text": text]]
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

// .serialized prevents concurrent access to the shared StubURLProtocol.requestHandler static.
@Suite(.serialized)
struct GeminiClientTests {
    @Test func generatesSuccessfully() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, candidatesResponse(text: #"{"foo":"bar"}"#))
        }
        let client = GeminiClient(apiKey: "test-key", session: makeStubSession())
        let result = try await client.generate(prompt: "hello", responseSchema: minimalSchema())
        #expect(result.text == #"{"foo":"bar"}"#)
    }

    @Test func requestIncludesApiKeyInQuery() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, candidatesResponse(text: "{}"))
        }
        let client = GeminiClient(apiKey: "my-secret-key", session: makeStubSession())
        _ = try await client.generate(prompt: "hi", responseSchema: minimalSchema())
        #expect(capturedRequest?.url?.query?.contains("key=my-secret-key") == true)
    }

    @Test func requestTargetsGemini25FlashEndpoint() async throws {
        var capturedRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, candidatesResponse(text: "{}"))
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())
        _ = try await client.generate(prompt: "hi", responseSchema: minimalSchema())
        #expect(capturedRequest?.url?.path.contains("models/gemini-2.5-flash:generateContent") == true)
        #expect(capturedRequest?.httpMethod == "POST")
    }

    @Test func requestBodyEmbedsPromptAndSchema() async throws {
        var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            capturedBody = readRequestBody(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, candidatesResponse(text: "{}"))
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())
        _ = try await client.generate(prompt: "translate this", responseSchema: minimalSchema())

        let body = try #require(capturedBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(json["contents"] as? [[String: Any]])
        let parts = try #require(contents.first?["parts"] as? [[String: Any]])
        #expect(parts.first?["text"] as? String == "translate this")

        let generationConfig = try #require(json["generationConfig"] as? [String: Any])
        #expect(generationConfig["responseMimeType"] as? String == "application/json")
        #expect(generationConfig["responseSchema"] is [String: Any])
    }

    @Test func throwsHttpErrorOnNon200Response() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())

        var caughtStatus: Int?
        do {
            _ = try await client.generate(prompt: "hi", responseSchema: minimalSchema())
        } catch let GeminiClient.GeminiError.httpError(statusCode, _) {
            caughtStatus = statusCode
        }
        #expect(caughtStatus == 429)
    }

    @Test func throwsMalformedResponseOnInvalidJson() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())

        var caughtMalformed = false
        do {
            _ = try await client.generate(prompt: "hi", responseSchema: minimalSchema())
        } catch GeminiClient.GeminiError.malformedResponse {
            caughtMalformed = true
        }
        #expect(caughtMalformed)
    }

    @Test func throwsMalformedResponseWhenCandidatesEmpty() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"candidates":[]}"#.data(using: .utf8)!)
        }
        let client = GeminiClient(apiKey: "k", session: makeStubSession())

        var caughtMalformed = false
        do {
            _ = try await client.generate(prompt: "hi", responseSchema: minimalSchema())
        } catch GeminiClient.GeminiError.malformedResponse {
            caughtMalformed = true
        }
        #expect(caughtMalformed)
    }
}
