public enum StudyDirection: String, Codable, CaseIterable, Sendable {
    case sourceToTarget = "source_to_target"
    case targetToSource = "target_to_source"
    case both

    public var displayName: String {
        switch self {
        case .sourceToTarget: return "Source → Target"
        case .targetToSource: return "Target → Source"
        case .both: return "Both Directions"
        }
    }
}
