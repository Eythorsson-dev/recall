import Testing
import Foundation
@testable import Core

/// Integration tests for `GoogleCloudTTSClient`. They make real network calls and
/// require a Google Cloud API key with the Text-to-Speech API enabled.
///
/// Set `GOOGLE_TTS_API_KEY` in the environment to run them. Tests are silently
/// skipped (via `withKnownIssue`) when the key is absent so CI without secrets
/// still passes.
private var apiKey: String? {
    ProcessInfo.processInfo.environment["GOOGLE_TTS_API_KEY"]
        .flatMap { $0.isEmpty ? nil : $0 }
}

private func skipIfNoKey() -> Bool {
    apiKey == nil
}

@Test func googleTTSAcceptsEnglishVoice() async throws {
    try await runVoiceTest(language: .english, text: "Hello, world.")
}

@Test func googleTTSAcceptsNorwegianVoice() async throws {
    try await runVoiceTest(language: .norwegian, text: "God morgen.")
}

@Test func googleTTSAcceptsUkrainianVoice() async throws {
    try await runVoiceTest(language: .ukrainian, text: "Привіт.")
}

private func runVoiceTest(language: Language, text: String) async throws {
    guard let key = apiKey else {
        withKnownIssue("GOOGLE_TTS_API_KEY not set — integration test skipped") {
            Issue.record("skipped")
        }
        return
    }
    let client = GoogleCloudTTSClient(apiKey: key)
    let data = try await client.generate(text: text, language: language)
    #expect(!data.isEmpty)
    // MP3 frame headers start with 0xFF, or RIFF/ID3 headers. A non-empty
    // response is enough to confirm the voice ID was accepted — a rejected
    // voice would return an HTTP 400.
}
