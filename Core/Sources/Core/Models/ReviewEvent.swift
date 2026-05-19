import Foundation
import GRDB

public struct ReviewEvent: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var cardId: Int64
    public var rating: Int
    public var studyMode: String
    public var direction: StudyDirection
    public var audioReplayCount: Int
    public var playbackSpeed: Double
    public var timeToRevealSeconds: Double
    public var timestamp: Date

    public init(
        id: Int64? = nil,
        cardId: Int64,
        rating: Int,
        studyMode: String = "reading",
        direction: StudyDirection,
        audioReplayCount: Int = 0,
        playbackSpeed: Double = 1.0,
        timeToRevealSeconds: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.cardId = cardId
        self.rating = rating
        self.studyMode = studyMode
        self.direction = direction
        self.audioReplayCount = audioReplayCount
        self.playbackSpeed = playbackSpeed
        self.timeToRevealSeconds = timeToRevealSeconds
        self.timestamp = timestamp
    }
}

extension ReviewEvent: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "reviewEvent"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
