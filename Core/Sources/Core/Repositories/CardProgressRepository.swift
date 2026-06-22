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
    /// Results are ordered by ascending retrievability (most-forgotten first).
    public func fetchDueForSession(
        deckIds: [Int64],
        direction: StudyDirection?,
        tagIds: [Int64] = [],
        before date: Date = Date()
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty else { return [] }

        let rows = try db.reader.read { dbConn -> [CardProgress] in
            let cardIds = try self.fetchCardIds(dbConn: dbConn, deckIds: deckIds, tagIds: tagIds)
            guard !cardIds.isEmpty else { return [] }

            var query = CardProgress
                .filter(cardIds.contains(Column("cardId")))
                .filter(Column("due") <= date)
                .filter(Column("fsrsState") != 0)

            if let dir = direction {
                query = query.filter(Column("direction") == dir.rawValue)
            }

            return try query.fetchAll(dbConn)
        }

        guard direction == nil else {
            return rows.sorted { retrievability($0, at: date) < retrievability($1, at: date) }
        }
        return applySiblingSupression(rows, tiebreaker: .sourceToTarget, at: date)
    }

    /// All CardProgress rows for practice mode (no due filter, no sibling suppression).
    public func fetchAllForSession(
        deckIds: [Int64],
        direction: StudyDirection?,
        tagIds: [Int64] = []
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty else { return [] }

        return try db.reader.read { dbConn -> [CardProgress] in
            let cardIds = try self.fetchCardIds(dbConn: dbConn, deckIds: deckIds, tagIds: tagIds)
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
        tagIds: [Int64] = [],
        before date: Date = Date()
    ) throws -> Int {
        try fetchDueForSession(deckIds: deckIds, direction: direction, tagIds: tagIds, before: date).count
    }

    /// CardProgress rows with fsrsState = 0 (never reviewed) in the given decks, up to `limit`.
    public func fetchNewCards(
        deckIds: [Int64],
        direction: StudyDirection?,
        tagIds: [Int64] = [],
        limit: Int
    ) throws -> [CardProgress] {
        guard !deckIds.isEmpty, limit > 0 else { return [] }
        return try db.reader.read { dbConn -> [CardProgress] in
            let cardIds = try self.fetchCardIds(dbConn: dbConn, deckIds: deckIds, tagIds: tagIds)
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

    /// Number of unique non-deleted cards across the given decks, optionally filtered by tags.
    public func fetchCardCount(deckIds: [Int64], tagIds: [Int64] = []) throws -> Int {
        guard !deckIds.isEmpty else { return 0 }
        return try db.reader.read { dbConn in
            let cardIds = try self.fetchCardIds(dbConn: dbConn, deckIds: deckIds, tagIds: tagIds)
            return cardIds.count
        }
    }

    /// Internal helper: fetch card IDs filtered by decks and optionally tags.
    private func fetchCardIds(dbConn: Database, deckIds: [Int64], tagIds: [Int64]) throws -> [Int64] {
        let deckPlaceholders = deckIds.map { _ in "?" }.joined(separator: ",")
        if tagIds.isEmpty {
            return try Int64.fetchAll(
                dbConn,
                sql: "SELECT id FROM card WHERE deckId IN (\(deckPlaceholders)) AND deletedAt IS NULL",
                arguments: StatementArguments(deckIds)
            )
        } else {
            let tagPlaceholders = tagIds.map { _ in "?" }.joined(separator: ",")
            var args = StatementArguments(deckIds)
            _ = args.append(contentsOf: StatementArguments(tagIds))
            return try Int64.fetchAll(
                dbConn,
                sql: """
                    SELECT DISTINCT c.id FROM card c
                    JOIN cardTag ct ON ct.cardId = c.id
                    WHERE c.deckId IN (\(deckPlaceholders))
                      AND c.deletedAt IS NULL
                      AND ct.tagId IN (\(tagPlaceholders))
                    """,
                arguments: args
            )
        }
    }

    private func applySiblingSupression(
        _ rows: [CardProgress],
        tiebreaker: StudyDirection,
        at date: Date
    ) -> [CardProgress] {
        var byCard: [Int64: [CardProgress]] = [:]
        for row in rows {
            byCard[row.cardId, default: []].append(row)
        }

        let deduplicated = byCard.values.map { siblings -> CardProgress in
            guard siblings.count > 1 else { return siblings[0] }
            let sorted = siblings.sorted { retrievability($0, at: date) < retrievability($1, at: date) }
            if retrievability(sorted[0], at: date) < retrievability(sorted[1], at: date) {
                return sorted[0]
            }
            return siblings.first { $0.direction == tiebreaker } ?? siblings[0]
        }

        return deduplicated.sorted { retrievability($0, at: date) < retrievability($1, at: date) }
    }

    // FSRS-5 retrievability: R(t, S) = (1 + factor·t/S)^decay
    // Lower value = more likely forgotten = higher urgency.
    private static let fsrsDecay: Double = -0.5
    private static let fsrsFactor: Double = pow(0.9, 1.0 / fsrsDecay) - 1  // 19/81

    private func retrievability(_ progress: CardProgress, at date: Date) -> Double {
        guard let lastReview = progress.lastReview, progress.stability > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(lastReview) / 86400.0
        return pow(1 + Self.fsrsFactor * elapsed / progress.stability, Self.fsrsDecay)
    }
}
