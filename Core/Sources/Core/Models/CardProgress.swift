import Foundation
import GRDB
import FSRSBridge

public struct CardProgress: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var cardId: Int64
    public var direction: StudyDirection

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

    public init(
        id: Int64? = nil,
        cardId: Int64,
        direction: StudyDirection,
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
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.cardId = cardId
        self.direction = direction
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
    }

    public func toFSRSFields() -> FSRSFields {
        FSRSFields(
            due: due,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            reps: reps,
            lapses: lapses,
            statusRaw: fsrsState,
            lastReview: lastReview ?? due
        )
    }

    public mutating func applyFSRSFields(_ fields: FSRSFields) {
        due = fields.due
        stability = fields.stability
        difficulty = fields.difficulty
        elapsedDays = fields.elapsedDays
        scheduledDays = fields.scheduledDays
        reps = fields.reps
        lapses = fields.lapses
        fsrsState = fields.statusRaw
        lastReview = fields.lastReview
        updatedAt = Date()
    }
}

extension CardProgress: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "cardProgress"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
