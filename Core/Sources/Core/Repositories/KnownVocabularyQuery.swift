import Foundation
import GRDB

public struct KnownVocabularyQuery: Sendable {
    public struct Entry: Sendable, Equatable {
        public let source: String
        public let target: String

        public init(source: String, target: String) {
            self.source = source
            self.target = target
        }
    }

    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    public func fetch(deckId: Int64) throws -> [Entry] {
        try db.reader.read { dbConn in
            try Row.fetchAll(
                dbConn,
                sql: """
                    SELECT c.sourceValue AS source, c.targetValue AS target
                    FROM card c
                    WHERE c.deckId = ?
                      AND c.kind = ?
                      AND c.deletedAt IS NULL
                      AND EXISTS (
                          SELECT 1 FROM cardProgress p
                          WHERE p.cardId = c.id
                            AND p.fsrsState >= 2
                      )
                    ORDER BY c.createdAt ASC
                    """,
                arguments: [deckId, CardKind.word.rawValue]
            ).map { row in
                Entry(source: row["source"], target: row["target"])
            }
        }
    }
}
