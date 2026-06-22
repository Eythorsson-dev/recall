import Foundation
import GRDB

public struct Tag: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Int64? = nil,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Tag: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "tag"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
