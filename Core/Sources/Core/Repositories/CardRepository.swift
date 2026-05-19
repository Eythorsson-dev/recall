import Foundation
import GRDB

public struct CardRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func insert(_ card: inout Card) throws {
        try db.writer.write { dbConn in
            try card.insert(dbConn)
        }
    }

    public func update(_ card: inout Card) throws {
        card.updatedAt = Date()
        try db.writer.write { dbConn in
            try card.update(dbConn)
        }
    }

    public func softDelete(_ card: inout Card) throws {
        card.deletedAt = Date()
        card.updatedAt = Date()
        try db.writer.write { dbConn in
            try card.update(dbConn)
        }
    }

    public func fetchAll(deckIds: [Int64]) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(deckIds.contains(Column("deckId")))
                .filter(Column("deletedAt") == nil)
                .order(Column("due").asc)
                .fetchAll(dbConn)
        }
    }

    public func fetchAll(deckId: Int64) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(Column("deckId") == deckId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(dbConn)
        }
    }

    public func fetchDue(deckId: Int64, before date: Date = Date()) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(Column("deckId") == deckId)
                .filter(Column("deletedAt") == nil)
                .filter(Column("due") <= date)
                .order(Column("due").asc)
                .fetchAll(dbConn)
        }
    }

    public func fetchDue(deckIds: [Int64], before date: Date = Date()) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(deckIds.contains(Column("deckId")))
                .filter(Column("deletedAt") == nil)
                .filter(Column("due") <= date)
                .order(Column("due").asc)
                .fetchAll(dbConn)
        }
    }

    public func fetchById(_ id: Int64) throws -> Card? {
        try db.reader.read { dbConn in
            try Card.fetchOne(dbConn, key: id)
        }
    }
}
