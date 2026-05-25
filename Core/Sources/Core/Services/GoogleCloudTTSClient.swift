import Foundation

/// Google Cloud TTS Neural2 client. Calls `texttospeech.googleapis.com/v1/text:synthesize`
/// and returns the synthesised audio as MP3 data.
public struct GoogleCloudTTSClient: TTSService {
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func generate(text: String, language: Language) async throws -> Data {
        var components = URLComponents(string: "https://texttospeech.googleapis.com/v1/text:synthesize")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            input: .init(text: text),
            voice: .init(languageCode: language.bcp47Locale, name: language.defaultVoiceID),
            audioConfig: .init(audioEncoding: "MP3")
        ))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TTSError.malformedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TTSError.httpError(statusCode: http.statusCode)
        }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let audio = Data(base64Encoded: decoded.audioContent), !audio.isEmpty else {
            throw TTSError.malformedResponse
        }
        return audio
    }

    public enum TTSError: Error, Equatable {
        case httpError(statusCode: Int)
        case malformedResponse
    }
}

private struct RequestBody: Encodable {
    let input: Input
    let voice: Voice
    let audioConfig: AudioConfig

    struct Input: Encodable { let text: String }
    struct Voice: Encodable { let languageCode: String; let name: String }
    struct AudioConfig: Encodable { let audioEncoding: String }
}

private struct ResponseBody: Decodable {
    let audioContent: String
}
