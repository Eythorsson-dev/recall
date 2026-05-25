import SwiftUI
import AVFoundation
import Core

struct SpeakerButton: View {
    let text: String
    let language: Language
    let player: TTSPlayer
    let onPlay: () -> Void

    @State private var isPlaying = false

    var body: some View {
        Button {
            play()
        } label: {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: 20))
                .foregroundStyle(.tint)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private func play() {
        guard !isPlaying else { return }
        isPlaying = true
        onPlay()
        player.play(text: text, language: language)
        // Reset playing state after estimated duration — exact length is unknown
        // without decoding the audio, and an ~equal estimate works for both the
        // cache-hit (AVAudioPlayer) and fallback (AVSpeechSynthesizer) paths.
        let duration = player.estimatedDuration(forText: text)
        Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run { isPlaying = false }
        }
    }
}

enum SpeechAudioSession {
    private static var didActivate = false

    static func activate() {
        // Default session category (.soloAmbient) honors the ringer switch —
        // TTS goes silent when the phone is on silent. Switch to .playback so
        // speech plays regardless, ducking other audio while we speak.
        // Idempotent: activated lazily on the first speak() call.
        guard !didActivate else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
        try? session.setActive(true, options: [])
        didActivate = true
    }
}
