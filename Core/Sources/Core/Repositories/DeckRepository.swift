import Foundation
import GRDB

public struct DeckRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func insert(_ deck: inout Deck) throws {
        try db.writer.write { dbConn in
            try deck.insert(dbConn)
        }
    }

    public func update(_ deck: inout Deck) throws {
        deck.updatedAt = Date()
        try db.writer.write { dbConn in
            try deck.update(dbConn)
        }
    }

    public func softDelete(_ deck: inout Deck) throws {
        deck.deletedAt = Date()
        deck.updatedAt = Date()
        try db.writer.write { dbConn in
            try deck.update(dbConn)
        }
    }

    public func fetchAll() throws -> [Deck] {
        try db.reader.read { dbConn in
            try Deck
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").asc)
                .fetchAll(dbConn)
        }
    }

    public func fetchById(_ id: Int64) throws -> Deck? {
        try db.reader.read { dbConn in
            try Deck.fetchOne(dbConn, key: id)
        }
    }
}
