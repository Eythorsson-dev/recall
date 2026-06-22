import Foundation
import GRDB

public struct TagRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func fetchAll() throws -> [Tag] {
        try db.reader.read { dbConn in
            try Tag.order(Column("name").asc).fetchAll(dbConn)
        }
    }

    public func insert(_ tag: inout Tag) throws {
        try db.writer.write { dbConn in
            try tag.insert(dbConn)
        }
    }

    public func update(_ tag: inout Tag) throws {
        tag.updatedAt = Date()
        try db.writer.write { dbConn in
            try tag.update(dbConn)
        }
    }

    public func delete(_ tag: Tag) throws {
        try db.writer.write { dbConn in
            try tag.delete(dbConn)
        }
    }

    public func fetchTags(forCard cardId: Int64) throws -> [Tag] {
        try db.reader.read { dbConn in
            try Tag.fetchAll(
                dbConn,
                sql: """
                    SELECT tag.* FROM tag
                    JOIN cardTag ON cardTag.tagId = tag.id
                    WHERE cardTag.cardId = ?
                    ORDER BY tag.name ASC
                    """,
                arguments: [cardId]
            )
        }
    }

    /// Replace all tags for a card atomically.
    public func setTags(_ tagIds: [Int64], forCard cardId: Int64) throws {
        try db.writer.write { dbConn in
            try dbConn.execute(
                sql: "DELETE FROM cardTag WHERE cardId = ?",
                arguments: [cardId]
            )
            for tagId in tagIds {
                try dbConn.execute(
                    sql: "INSERT OR IGNORE INTO cardTag (cardId, tagId) VALUES (?, ?)",
                    arguments: [cardId, tagId]
                )
            }
        }
    }

    /// Returns tags whose names contain the query string (case-insensitive, diacritic-insensitive).
    public func searchTags(matching query: String) throws -> [Tag] {
        let all = try fetchAll()
        guard !query.isEmpty else { return all }
        let folded = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return all.filter { tag in
            tag.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .contains(folded)
        }
    }
}
