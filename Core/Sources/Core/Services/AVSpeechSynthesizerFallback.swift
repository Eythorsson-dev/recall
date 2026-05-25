import Foundation
import AVFoundation

/// On-device TTS using `AVSpeechSynthesizer`. The "not silent" stopgap engine —
/// invoked only when no cached audio exists and the device is offline.
///
/// - `generate(text:language:)` returns WAV-encoded PCM audio data (PCM is captured
///   via `AVSpeechSynthesizer.write(_:toBufferCallback:)` and wrapped in a WAV header).
/// - `speak(text:language:)` performs direct, real-time playback through the system
///   speaker without going through the cache.
public final class AVSpeechSynthesizerFallback: TTSService, @unchecked Sendable {
    private let liveSynthesizer = AVSpeechSynthesizer()

    public init() {}

    public func generate(text: String, language: Language) async throws -> Data {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.bcp47Locale)

        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = AVSpeechSynthesizer()
            var pcmBuffers: [AVAudioPCMBuffer] = []
            var settled = false

            synthesizer.write(utterance) { buffer in
                guard !settled else { return }
                guard let pcm = buffer as? AVAudioPCMBuffer else {
                    settled = true
                    continuation.resume(throwing: SynthesisError.unsupportedBufferType)
                    return
                }
                if pcm.frameLength == 0 {
                    settled = true
                    // Hold a reference to the synthesizer until completion so its
                    // worker isn't torn down mid-write.
                    _ = synthesizer
                    continuation.resume(returning: Self.wav(from: pcmBuffers))
                    return
                }
                pcmBuffers.append(pcm)
            }
        }
    }

    /// Real-time playback used by `SpeakerButton` when the cache misses.
    public func speak(text: String, language: Language) {
        guard !liveSynthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.bcp47Locale)
        liveSynthesizer.speak(utterance)
    }

    public enum SynthesisError: Error { case unsupportedBufferType }

    /// Serialise captured float PCM buffers as a 16-bit little-endian WAV blob.
    private static func wav(from buffers: [AVAudioPCMBuffer]) -> Data {
        guard let first = buffers.first else { return Data() }
        let sampleRate = UInt32(first.format.sampleRate)
        let channels = UInt16(first.format.channelCount)
        let bitsPerSample: UInt16 = 16
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign = channels * bitsPerSample / 8

        var pcmData = Data()
        for buffer in buffers {
            guard let channelData = buffer.floatChannelData else { continue }
            let frames = Int(buffer.frameLength)
            for frame in 0..<frames {
                for ch in 0..<Int(channels) {
                    let sample = channelData[ch][frame]
                    let clamped = max(-1.0, min(1.0, sample))
                    let int16 = Int16(clamped * Float(Int16.max))
                    Swift.withUnsafeBytes(of: int16.littleEndian) { pcmData.append(contentsOf: $0) }
                }
            }
        }

        var wav = Data()
        wav.append("RIFF")
        wav.append(uint32: UInt32(36 + pcmData.count))
        wav.append("WAVE")
        wav.append("fmt ")
        wav.append(uint32: 16)
        wav.append(uint16: 1) // PCM
        wav.append(uint16: channels)
        wav.append(uint32: sampleRate)
        wav.append(uint32: byteRate)
        wav.append(uint16: blockAlign)
        wav.append(uint16: bitsPerSample)
        wav.append("data")
        wav.append(uint32: UInt32(pcmData.count))
        wav.append(pcmData)
        return wav
    }
}

private extension Data {
    mutating func append(_ ascii: String) {
        append(contentsOf: ascii.utf8)
    }
    mutating func append(uint32 value: UInt32) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
    mutating func append(uint16 value: UInt16) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
