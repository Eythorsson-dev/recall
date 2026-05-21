import Foundation

public struct TranslationService: Sendable {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func translate(_ text: String, from source: Language, to target: Language) async throws -> String {
        var components = URLComponents(string: "https://translation.googleapis.com/language/translate/v2")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(q: text, source: source.rawValue, target: target.rawValue))

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.malformedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TranslationError.httpError(statusCode: http.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let translatedText = decoded.data.translations.first?.translatedText else {
            throw TranslationError.malformedResponse
        }
        return translatedText
    }

    public enum TranslationError: Error, Equatable {
        case httpError(statusCode: Int)
        case malformedResponse
    }
}

private struct RequestBody: Encodable {
    let q: String
    let source: String
    let target: String
    let format = "text"
}

private struct ResponseBody: Decodable {
    let data: TranslationData

    struct TranslationData: Decodable {
        let translations: [Translation]

        struct Translation: Decodable {
            let translatedText: String
        }
    }
}
