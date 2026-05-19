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

    public func fetchAll() throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(dbConn)
        }
    }

    public func fetchDue(before date: Date = Date()) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
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
