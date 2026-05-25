import Foundation
import GRDB

public struct CardRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func insert(_ card: inout Card) throws {
        try db.writer.write { dbConn in
            try Self.insertCard(&card, dbConn: dbConn)
        }
    }

    /// Atomically inserts every card in `cards`, plus the two `CardProgress` rows
    /// per card, in a single transaction. If any row fails (FK violation, schema
    /// violation, etc.), the whole batch rolls back and the IDs on `cards` are
    /// reset to nil so the caller can re-stage.
    public func insertAll(_ cards: inout [Card]) throws {
        do {
            try db.writer.write { dbConn in
                for index in cards.indices {
                    try Self.insertCard(&cards[index], dbConn: dbConn)
                }
            }
        } catch {
            for index in cards.indices { cards[index].id = nil }
            throw error
        }
    }

    private static func insertCard(_ card: inout Card, dbConn: Database) throws {
        try card.insert(dbConn)
        guard let cardId = card.id else { return }
        let now = Date()
        var progressS = CardProgress(cardId: cardId, direction: .sourceToTarget, createdAt: now, updatedAt: now)
        var progressT = CardProgress(cardId: cardId, direction: .targetToSource, createdAt: now, updatedAt: now)
        try progressS.insert(dbConn)
        try progressT.insert(dbConn)
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
                .order(Column("createdAt").desc)
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

    public func fetchAll(deckId: Int64, kind: CardKind) throws -> [Card] {
        try db.reader.read { dbConn in
            try Card
                .filter(Column("deckId") == deckId)
                .filter(Column("kind") == kind.rawValue)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(dbConn)
        }
    }

    public func fetchById(_ id: Int64) throws -> Card? {
        try db.reader.read { dbConn in
            try Card.fetchOne(dbConn, key: id)
        }
    }
}
