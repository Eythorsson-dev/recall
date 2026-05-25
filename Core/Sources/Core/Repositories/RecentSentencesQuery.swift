import Foundation
import GRDB

public struct RecentSentencesQuery: Sendable {
    public static let defaultLimit = 30

    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func fetch(deckId: Int64, limit: Int = defaultLimit) throws -> [String] {
        try db.reader.read { dbConn in
            try String.fetchAll(
                dbConn,
                sql: """
                    SELECT targetValue
                    FROM card
                    WHERE deckId = ?
                      AND kind = ?
                      AND deletedAt IS NULL
                    ORDER BY createdAt DESC
                    LIMIT ?
                    """,
                arguments: [deckId, CardKind.sentence.rawValue, limit]
            )
        }
    }
}
