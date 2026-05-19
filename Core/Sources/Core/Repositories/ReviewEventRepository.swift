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
}
