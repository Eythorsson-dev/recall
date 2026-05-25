import Foundation
import GRDB

/// Which side of a Card's speakable fields a TTS job targets.
public enum FieldSide: String, Codable, CaseIterable, Sendable {
    case source
    case target
}

/// Status of a pending TTS generation job. `failed` jobs stay in the queue and are
/// retried the next time `TTSGenerationQueue.processPending()` runs.
public enum TTSJobStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case failed
}

public struct TTSGenerationJob: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var cardId: Int64
    public var fieldSide: FieldSide
    public var text: String
    public var language: Language
    public var status: TTSJobStatus
    public var createdAt: Date

    public init(
        id: Int64? = nil,
        cardId: Int64,
        fieldSide: FieldSide,
        text: String,
        language: Language,
        status: TTSJobStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.cardId = cardId
        self.fieldSide = fieldSide
        self.text = text
        self.language = language
        self.status = status
        self.createdAt = createdAt
    }
}

extension TTSGenerationJob: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "ttsGenerationJob"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
