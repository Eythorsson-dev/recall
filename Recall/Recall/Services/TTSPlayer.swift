import Foundation
import AVFoundation
import Core

/// Cache-first playback for speakable Fields.
/// On a cache hit, plays the stored file via `AVAudioPlayer`.
/// On a miss, speaks the text in real time via `AVSpeechSynthesizerFallback`.
@MainActor
final class TTSPlayer: ObservableObject {
    let cache: AudioCache
    private let fallback: AVSpeechSynthesizerFallback
    private var player: AVAudioPlayer?

    init(cache: AudioCache, fallback: AVSpeechSynthesizerFallback) {
        self.cache = cache
        self.fallback = fallback
    }

    /// Plays `text` for `language`. Returns true if a cached file was played, false
    /// if the on-device fallback was used — callers can use this to surface state.
    @discardableResult
    func play(text: String, language: Language) -> Bool {
        SpeechAudioSession.activate()
        let key = AudioCache.key(text: text, language: language, voiceID: language.defaultVoiceID)
        if let data = cache.retrieve(forKey: key) {
            do {
                player = try AVAudioPlayer(data: data)
                player?.play()
                return true
            } catch {
                // AVAudioPlayer couldn't decode the file (corrupt or unsupported format).
                // Fall through to the on-device synthesiser so the user isn't left in silence.
            }
        }
        fallback.speak(text: text, language: language)
        return false
    }

    /// Best-effort playback duration estimate for UI state. Real duration is unknown
    /// without decoding the audio header — this is "good enough" for the speaker icon
    /// flip-back animation.
    func estimatedDuration(forText text: String) -> Double {
        max(1.5, Double(text.count) * 0.08)
    }
}
