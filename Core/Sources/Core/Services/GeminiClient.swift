import Foundation

public struct GeminiResponse: Sendable {
    public let text: String
}

public struct GeminiClient: Sendable {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func generate(prompt: String, responseSchema: Data) async throws -> GeminiResponse {
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeRequestBody(prompt: prompt, responseSchema: responseSchema)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GeminiError.transportError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.malformedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw GeminiError.httpError(statusCode: http.statusCode, body: body)
        }

        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let text = decoded.candidates.first?.content.parts.first?.text else {
            throw GeminiError.malformedResponse
        }
        return GeminiResponse(text: text)
    }

    public enum GeminiError: Error, CustomStringConvertible {
        case httpError(statusCode: Int, body: String?)
        case malformedResponse
        case transportError(Error)

        public var description: String {
            switch self {
            case .httpError(let statusCode, let body):
                if let body, !body.isEmpty {
                    return "Gemini HTTP \(statusCode): \(body)"
                }
                return "Gemini HTTP \(statusCode)"
            case .malformedResponse:
                return "Gemini returned a malformed response"
            case .transportError(let error):
                return "Gemini transport error: \(error.localizedDescription)"
            }
        }
    }

    private func makeRequestBody(prompt: String, responseSchema: Data) throws -> Data {
        let schemaObject = try JSONSerialization.jsonObject(with: responseSchema)
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schemaObject
            ]
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }
}

private struct ResponseBody: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content

        struct Content: Decodable {
            let parts: [Part]

            struct Part: Decodable {
                let text: String
            }
        }
    }
}
