import Foundation
import GRDB
import FSRS

public struct Card: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var language: String
    public var sourceField: String
    public var targetField: String
    public var sourceValue: String
    public var targetValue: String
    public var sourceSpeakable: Bool
    public var targetSpeakable: Bool

    public var due: Date
    public var stability: Double
    public var difficulty: Double
    public var elapsedDays: Double
    public var scheduledDays: Double
    public var reps: Int
    public var lapses: Int
    public var fsrsState: Int
    public var lastReview: Date?
    public var learningSteps: Int

    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: Int64? = nil,
        language: String,
        sourceField: String,
        targetField: String,
        sourceValue: String = "",
        targetValue: String = "",
        sourceSpeakable: Bool = false,
        targetSpeakable: Bool = false,
        due: Date = Date(),
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        reps: Int = 0,
        lapses: Int = 0,
        fsrsState: Int = 0,
        lastReview: Date? = nil,
        learningSteps: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.language = language
        self.sourceField = sourceField
        self.targetField = targetField
        self.sourceValue = sourceValue
        self.targetValue = targetValue
        self.sourceSpeakable = sourceSpeakable
        self.targetSpeakable = targetSpeakable
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reps = reps
        self.lapses = lapses
        self.fsrsState = fsrsState
        self.lastReview = lastReview
        self.learningSteps = learningSteps
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    public var cardState: CardState {
        CardState(rawValue: fsrsState) ?? .new
    }

    public func toFSRSCard() -> FSRS.Card {
        var fsrsCard = FSRS.Card()
        fsrsCard.due = due
        fsrsCard.stability = stability
        fsrsCard.difficulty = difficulty
        fsrsCard.elapsedDays = elapsedDays
        fsrsCard.scheduledDays = scheduledDays
        fsrsCard.reps = Int(reps)
        fsrsCard.lapses = Int(lapses)
        fsrsCard.state = cardState
        fsrsCard.lastReview = lastReview ?? Date(timeIntervalSince1970: 0)
        fsrsCard.learningSteps = Int(learningSteps)
        return fsrsCard
    }

    public mutating func applyFSRS(_ fsrsCard: FSRS.Card) {
        due = fsrsCard.due
        stability = fsrsCard.stability
        difficulty = fsrsCard.difficulty
        elapsedDays = fsrsCard.elapsedDays
        scheduledDays = fsrsCard.scheduledDays
        reps = Int(fsrsCard.reps)
        lapses = Int(fsrsCard.lapses)
        fsrsState = Int(fsrsCard.state.rawValue)
        lastReview = fsrsCard.lastReview
        learningSteps = Int(fsrsCard.learningSteps)
        updatedAt = Date()
    }
}

extension Card: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "card"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
