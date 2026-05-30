import Foundation
import GRDB

public struct ReviewEventRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func insert(_ event: inout ReviewEvent) throws {
        try db.writer.write { dbConn in
            try event.insert(dbConn)
        }
    }

    public func fetchAll(forCard cardId: Int64) throws -> [ReviewEvent] {
        try db.reader.read { dbConn in
            try ReviewEvent
                .filter(Column("cardId") == cardId)
                .order(Column("timestamp").desc)
                .fetchAll(dbConn)
        }
    }

    /// Count of distinct cards (in the given decks) whose first-ever ReviewEvent falls on today.
    public func fetchTodayNewCardCount(deckIds: [Int64]) throws -> Int {
        guard !deckIds.isEmpty else { return 0 }
        return try db.reader.read { dbConn in
            let placeholders = deckIds.map { _ in "?" }.joined(separator: ",")
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            return try Int.fetchOne(
                dbConn,
                sql: """
                SELECT COUNT(*) FROM (
                    SELECT cardId FROM reviewEvent
                    WHERE cardId IN (
                        SELECT id FROM card WHERE deckId IN (\(placeholders)) AND deletedAt IS NULL
                    )
                    GROUP BY cardId
                    HAVING MIN(timestamp) >= ? AND MIN(timestamp) < ?
                )
                """,
                arguments: StatementArguments(deckIds + [startOfToday, startOfTomorrow])
            ) ?? 0
        }
    }
}
