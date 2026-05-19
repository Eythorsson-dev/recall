import Foundation
import GRDB

public struct Deck: Codable, Identifiable, Sendable {
    public var id: Int64?
    public var name: String
    public var sourceLanguage: Language
    public var targetLanguage: Language
    public var sourceSpeakable: Bool
    public var targetSpeakable: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public var sourceField: String { sourceLanguage.displayName }
    public var targetField: String { targetLanguage.displayName }

    public init(
        id: Int64? = nil,
        name: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        sourceSpeakable: Bool = false,
        targetSpeakable: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.sourceSpeakable = sourceSpeakable
        self.targetSpeakable = targetSpeakable
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension Deck: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "deck"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
