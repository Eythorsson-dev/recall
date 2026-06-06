import Foundation
import GRDB

public struct SettingsRepository: Sendable {
    private let db: DatabaseManager

    public init(database: DatabaseManager) {
        self.db = database
    }

    // MARK: - Study Direction

    public func studyDirection() throws -> StudyDirection? {
        try db.reader.read { dbConn in
            guard let raw = try String.fetchOne(dbConn, sql: "SELECT value FROM settings WHERE key = 'studyDirection'") else {
                return nil
            }
            return StudyDirection(rawValue: raw)
        }
    }

    public func setStudyDirection(_ direction: StudyDirection?) throws {
        try db.writer.write { dbConn in
            if let direction {
                try dbConn.execute(
                    sql: "INSERT OR REPLACE INTO settings (key, value) VALUES ('studyDirection', ?)",
                    arguments: [direction.rawValue]
                )
            } else {
                try dbConn.execute(sql: "DELETE FROM settings WHERE key = 'studyDirection'")
            }
        }
    }

    // MARK: - Review Limit

    public func reviewLimit() throws -> Int? {
        try db.reader.read { dbConn in
            guard let raw = try String.fetchOne(dbConn, sql: "SELECT value FROM settings WHERE key = 'reviewLimit'"),
                  let value = Int(raw) else {
                return nil
            }
            return value
        }
    }

    public func setReviewLimit(_ limit: Int?) throws {
        try db.writer.write { dbConn in
            if let limit {
                try dbConn.execute(
                    sql: "INSERT OR REPLACE INTO settings (key, value) VALUES ('reviewLimit', ?)",
                    arguments: [String(limit)]
                )
            } else {
                try dbConn.execute(sql: "DELETE FROM settings WHERE key = 'reviewLimit'")
            }
        }
    }

    // MARK: - Study Mode

    public func studyMode() throws -> StudyMode {
        try db.reader.read { dbConn in
            guard let raw = try String.fetchOne(dbConn, sql: "SELECT value FROM settings WHERE key = 'studyMode'"),
                  let mode = StudyMode(rawValue: raw) else {
                return .reading
            }
            return mode
        }
    }

    public func setStudyMode(_ mode: StudyMode) throws {
        try db.writer.write { dbConn in
            try dbConn.execute(
                sql: "INSERT OR REPLACE INTO settings (key, value) VALUES ('studyMode', ?)",
                arguments: [mode.rawValue]
            )
        }
    }

}
