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
}
