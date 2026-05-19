import Foundation
import GRDB

public struct Card: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var language: String
    public var sourceField: String
    public var targetField: String
    public var sourceValue: String
    public var targetValue: String
    public var sourceSpeakable: Bool
    public var targetSpeakable: Bool
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension Card: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "card"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
