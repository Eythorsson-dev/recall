import Foundation

/// Generates speech audio data for a piece of text in a given language.
/// Implementations: cloud (`GoogleCloudTTSClient`) and on-device fallback (`AVSpeechSynthesizerFallback`).
public protocol TTSService: Sendable {
    func generate(text: String, language: Language) async throws -> Data
}
