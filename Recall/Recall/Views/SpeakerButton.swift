import SwiftUI
import AVFoundation
import Core

struct SpeakerButton: View {
    let text: String
    let language: Language
    let onPlay: () -> Void

    @State private var isPlaying = false

    private static let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        Button {
            speak()
        } label: {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: 20))
                .foregroundStyle(.tint)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private func speak() {
        guard !Self.synthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.bcp47Locale)
        isPlaying = true
        onPlay()
        Self.synthesizer.speak(utterance)
        // Reset playing state after estimated duration
        let duration = max(1.5, Double(text.count) * 0.08)
        Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run { isPlaying = false }
        }
    }
}
