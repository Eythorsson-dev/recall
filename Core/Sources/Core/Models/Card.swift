import Foundation
import GRDB

public struct Card: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var deckId: Int64
    public var sourceValue: String
    public var targetValue: String

    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: Int64? = nil,
        deckId: Int64,
        sourceValue: String = "",
        targetValue: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.deckId = deckId
        self.sourceValue = sourceValue
        self.targetValue = targetValue
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
