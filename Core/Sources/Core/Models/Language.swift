public enum Language: String, Codable, CaseIterable, Sendable {
    case english = "en"
    case norwegian = "no"
    case ukrainian = "uk"

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .norwegian: return "Norwegian"
        case .ukrainian: return "Ukrainian"
        }
    }

    public var bcp47Locale: String {
        switch self {
        case .english: return "en-US"
        case .norwegian: return "nb-NO"
        case .ukrainian: return "uk-UA"
        }
    }

    /// Google Cloud TTS voice ID used to generate audio for this language.
    /// Neural2 is the target tier; Norwegian and Ukrainian have no Neural2 voices,
    /// so the highest-fidelity Wavenet voice is used instead.
    public var defaultVoiceID: String {
        switch self {
        case .english: return "en-US-Neural2-C"
        case .norwegian: return "nb-NO-Wavenet-E"
        case .ukrainian: return "uk-UA-Wavenet-A"
        }
    }
}
