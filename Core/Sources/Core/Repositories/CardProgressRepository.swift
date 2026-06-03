import Foundation
import GRDB

public struct CardProgressRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func insert(_ progress: inout CardProgress) throws {
        try db.writer.write { dbConn in
            try progress.insert(dbConn)
        }
    }

    public func fetchAll(forCard cardId: Int64) throws -> [CardProgress] {
        try db.reader.read { dbConn in
            try CardProgress
                .filter(Column("cardId") == cardId)
                .fetchAll(dbConn)
        }
    }

    public func fetch(cardId: Int64, direction: StudyDirection) throws -> CardProgress? {
        try db.reader.read { dbConn in
            try CardProgress
                .filter(Column("cardId") == cardId)
                .filter(Column("direction") == direction.rawValue)
                .fetchOne(dbConn)
        }
    }

    public func update(_ progress: inout CardProgress) throws {
        progress.updatedAt = Date()
        try db.writer.write { dbConn in
            try progress.update(dbConn)
        }
    }

    /// Due CardProgress rows for the session queue, with sibling suppression when direction is nil.
    /// Sibling suppression: if both directions of the same card are due, only the more overdue
    /// one enters the queue. Tiebreaker: prefer sourceToTarget unless direction is explicitly targetToSource.
    public func fetchDueForSession(
        deckIds: [Int64],
        direction: StudyDirection?,
        before date: Date = Date()
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty else { return [] }

        let rows = try db.reader.read { dbConn -> [CardProgress] in
            let placeholders = deckIds.map { _ in "?" }.joined(separator: ",")
            let cardIds = try Int64.fetchAll(
                dbConn,
                sql: "SELECT id FROM card WHERE deckId IN (\(placeholders)) AND deletedAt IS NULL",
                arguments: StatementArguments(deckIds)
            )
            guard !cardIds.isEmpty else { return [] }

            var query = CardProgress
                .filter(cardIds.contains(Column("cardId")))
                .filter(Column("due") <= date)
                .filter(Column("fsrsState") != 0)
                .order(Column("due").asc)

            if let dir = direction {
                query = query.filter(Column("direction") == dir.rawValue)
            }

            return try query.fetchAll(dbConn)
        }

        guard direction == nil else { return rows }
        return applySiblingSupression(rows, tiebreaker: .sourceToTarget)
    }

    /// All CardProgress rows for practice mode (no due filter, no sibling suppression).
    public func fetchAllForSession(
        deckIds: [Int64],
        direction: StudyDirection?
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty else { return [] }

        return try db.reader.read { dbConn -> [CardProgress] in
            let placeholders = deckIds.map { _ in "?" }.joined(separator: ",")
            let cardIds = try Int64.fetchAll(
                dbConn,
                sql: "SELECT id FROM card WHERE deckId IN (\(placeholders)) AND deletedAt IS NULL",
                arguments: StatementArguments(deckIds)
            )
            guard !cardIds.isEmpty else { return [] }

            var query = CardProgress
                .filter(cardIds.contains(Column("cardId")))
                .order(Column("cardId").asc)

            if let dir = direction {
                query = query.filter(Column("direction") == dir.rawValue)
            }

            return try query.fetchAll(dbConn)
        }
    }

    /// Number of due items after sibling suppression.
    public func fetchDueCount(
        deckIds: [Int64],
        direction: StudyDirection?,
        before date: Date = Date()
    ) throws -> Int {
        try fetchDueForSession(deckIds: deckIds, direction: direction, before: date).count
    }

    /// CardProgress rows with fsrsState = 0 (never reviewed) in the given decks, up to `limit`.
    public func fetchNewCards(
        deckIds: [Int64],
        direction: StudyDirection?,
        limit: Int
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty, limit > 0 else { return [] }
        return try db.reader.read { dbConn -> [CardProgress] in
            let placeholders = deckIds.map { _ in "?" }.joined(separator: ",")
            let cardIds = try Int64.fetchAll(
                dbConn,
                sql: "SELECT id FROM card WHERE deckId IN (\(placeholders)) AND deletedAt IS NULL",
                arguments: StatementArguments(deckIds)
            )
            guard !cardIds.isEmpty else { return [] }
            var query = CardProgress
                .filter(cardIds.contains(Column("cardId")))
                .filter(Column("fsrsState") == 0)
                .order(Column("cardId").asc)
                .limit(limit)
            if let dir = direction {
                query = query.filter(Column("direction") == dir.rawValue)
            }
            return try query.fetchAll(dbConn)
        }
    }

    /// Number of unique non-deleted cards across the given decks.
    public func fetchCardCount(deckIds: [Int64]) throws -> Int {
        guard !deckIds.isEmpty else { return 0 }
        return try db.reader.read { dbConn in
            try Card
                .filter(deckIds.contains(Column("deckId")))
                .filter(Column("deletedAt") == nil)
                .fetchCount(dbConn)
        }
    }

    private func applySiblingSupression(
        _ rows: [CardProgress],
        tiebreaker: StudyDirection
    ) -> [CardProgress] {
        var byCard: [Int64: [CardProgress]] = [:]
        for row in rows {
            byCard[row.cardId, default: []].append(row)
        }

        let deduplicated = byCard.values.map { siblings -> CardProgress in
            guard siblings.count > 1 else { return siblings[0] }
            let sorted = siblings.sorted { $0.due < $1.due }
            if sorted[0].due < sorted[1].due {
                return sorted[0]
            }
            return siblings.first { $0.direction == tiebreaker } ?? siblings[0]
        }

        return deduplicated.sorted { $0.due < $1.due }
    }
}
