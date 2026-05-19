import Foundation
import GRDB

public final class DatabaseManager: Sendable {
    private let dbWriter: any DatabaseWriter

    public init(path: String) throws {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let pool = try DatabasePool(path: path, configuration: config)
        self.dbWriter = pool
        try Self.migrate(dbWriter)
    }

    private init(queue: DatabaseQueue) throws {
        self.dbWriter = queue
        try Self.migrate(queue)
    }

    public var reader: any DatabaseReader { dbWriter }
    public var writer: any DatabaseWriter { dbWriter }

    public static func inMemory() throws -> DatabaseManager {
        var config = Configuration()
        config.foreignKeysEnabled = true
        let queue = try DatabaseQueue(configuration: config)
        return try DatabaseManager(queue: queue)
    }

    private static func migrate(_ writer: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_cards") { db in
            try db.create(table: "card") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("language", .text).notNull()
                t.column("sourceField", .text).notNull()
                t.column("targetField", .text).notNull()
                t.column("sourceValue", .text).notNull().defaults(to: "")
                t.column("targetValue", .text).notNull().defaults(to: "")
                t.column("sourceSpeakable", .boolean).notNull().defaults(to: false)
                t.column("targetSpeakable", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }

        try migrator.migrate(writer)
    }
}
