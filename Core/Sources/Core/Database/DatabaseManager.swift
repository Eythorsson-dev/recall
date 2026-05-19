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

        migrator.registerMigration("v2_fsrs_and_review_events") { db in
            try db.alter(table: "card") { t in
                t.add(column: "due", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.add(column: "stability", .double).notNull().defaults(to: 0)
                t.add(column: "difficulty", .double).notNull().defaults(to: 0)
                t.add(column: "elapsedDays", .double).notNull().defaults(to: 0)
                t.add(column: "scheduledDays", .double).notNull().defaults(to: 0)
                t.add(column: "reps", .integer).notNull().defaults(to: 0)
                t.add(column: "lapses", .integer).notNull().defaults(to: 0)
                t.add(column: "fsrsState", .integer).notNull().defaults(to: 0)
                t.add(column: "lastReview", .datetime)
                t.add(column: "learningSteps", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "reviewEvent") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cardId", .integer).notNull().references("card", onDelete: .cascade)
                t.column("rating", .integer).notNull()
                t.column("studyMode", .text).notNull().defaults(to: "reading")
                t.column("direction", .text).notNull()
                t.column("audioReplayCount", .integer).notNull().defaults(to: 0)
                t.column("playbackSpeed", .double).notNull().defaults(to: 1.0)
                t.column("timeToRevealSeconds", .double).notNull()
                t.column("timestamp", .datetime).notNull()
            }
        }

        migrator.registerMigration("v3_explicit_language_pair") { db in
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.create(table: "card_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sourceLanguage", .text).notNull()
                t.column("targetLanguage", .text).notNull()
                t.column("sourceValue", .text).notNull().defaults(to: "")
                t.column("targetValue", .text).notNull().defaults(to: "")
                t.column("sourceSpeakable", .boolean).notNull().defaults(to: false)
                t.column("targetSpeakable", .boolean).notNull().defaults(to: false)
                t.column("due", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("stability", .double).notNull().defaults(to: 0)
                t.column("difficulty", .double).notNull().defaults(to: 0)
                t.column("elapsedDays", .double).notNull().defaults(to: 0)
                t.column("scheduledDays", .double).notNull().defaults(to: 0)
                t.column("reps", .integer).notNull().defaults(to: 0)
                t.column("lapses", .integer).notNull().defaults(to: 0)
                t.column("fsrsState", .integer).notNull().defaults(to: 0)
                t.column("lastReview", .datetime)
                t.column("learningSteps", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
            try db.execute(sql: """
                INSERT INTO card_new (id, sourceLanguage, targetLanguage, sourceValue, targetValue,
                                      sourceSpeakable, targetSpeakable, due, stability, difficulty,
                                      elapsedDays, scheduledDays, reps, lapses, fsrsState,
                                      lastReview, learningSteps, createdAt, updatedAt, deletedAt)
                SELECT id, language, language, sourceValue, targetValue,
                       sourceSpeakable, targetSpeakable, due, stability, difficulty,
                       elapsedDays, scheduledDays, reps, lapses, fsrsState,
                       lastReview, learningSteps, createdAt, updatedAt, deletedAt
                FROM card
            """)
            try db.drop(table: "card")
            try db.rename(table: "card_new", to: "card")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        migrator.registerMigration("v4_introduce_decks") { db in
            try db.create(table: "deck") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("sourceLanguage", .text).notNull()
                t.column("targetLanguage", .text).notNull()
                t.column("sourceSpeakable", .boolean).notNull().defaults(to: false)
                t.column("targetSpeakable", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }

            // One deck per unique language pair from existing cards
            try db.execute(sql: """
                INSERT INTO deck (name, sourceLanguage, targetLanguage, sourceSpeakable, targetSpeakable, createdAt, updatedAt)
                SELECT DISTINCT
                    sourceLanguage || ' → ' || targetLanguage,
                    sourceLanguage, targetLanguage,
                    MAX(sourceSpeakable), MAX(targetSpeakable),
                    MIN(createdAt), MIN(createdAt)
                FROM card
                GROUP BY sourceLanguage, targetLanguage
            """)

            try db.execute(sql: "PRAGMA foreign_keys = OFF")

            try db.create(table: "card_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("deckId", .integer).notNull().references("deck", onDelete: .cascade)
                t.column("sourceValue", .text).notNull().defaults(to: "")
                t.column("targetValue", .text).notNull().defaults(to: "")
                t.column("due", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("stability", .double).notNull().defaults(to: 0)
                t.column("difficulty", .double).notNull().defaults(to: 0)
                t.column("elapsedDays", .double).notNull().defaults(to: 0)
                t.column("scheduledDays", .double).notNull().defaults(to: 0)
                t.column("reps", .integer).notNull().defaults(to: 0)
                t.column("lapses", .integer).notNull().defaults(to: 0)
                t.column("fsrsState", .integer).notNull().defaults(to: 0)
                t.column("lastReview", .datetime)
                t.column("learningSteps", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }

            try db.execute(sql: """
                INSERT INTO card_new (id, deckId, sourceValue, targetValue, due, stability, difficulty,
                                      elapsedDays, scheduledDays, reps, lapses, fsrsState,
                                      lastReview, learningSteps, createdAt, updatedAt, deletedAt)
                SELECT c.id,
                       d.id,
                       c.sourceValue, c.targetValue, c.due, c.stability, c.difficulty,
                       c.elapsedDays, c.scheduledDays, c.reps, c.lapses, c.fsrsState,
                       c.lastReview, c.learningSteps, c.createdAt, c.updatedAt, c.deletedAt
                FROM card c
                JOIN deck d ON d.sourceLanguage = c.sourceLanguage AND d.targetLanguage = c.targetLanguage
            """)

            try db.drop(table: "card")
            try db.rename(table: "card_new", to: "card")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        migrator.registerMigration("v5_card_progress") { db in
            try db.create(table: "cardProgress") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cardId", .integer).notNull().references("card", onDelete: .cascade)
                t.column("direction", .text).notNull()
                t.column("due", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("stability", .double).notNull().defaults(to: 0)
                t.column("difficulty", .double).notNull().defaults(to: 0)
                t.column("elapsedDays", .double).notNull().defaults(to: 0)
                t.column("scheduledDays", .double).notNull().defaults(to: 0)
                t.column("reps", .integer).notNull().defaults(to: 0)
                t.column("lapses", .integer).notNull().defaults(to: 0)
                t.column("fsrsState", .integer).notNull().defaults(to: 0)
                t.column("lastReview", .datetime)
                t.column("learningSteps", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(
                index: "cardProgress_cardId_direction",
                on: "cardProgress",
                columns: ["cardId", "direction"],
                unique: true
            )

            // Copy existing FSRS data into both direction rows for every card
            for direction in ["source_to_target", "target_to_source"] {
                try db.execute(sql: """
                    INSERT INTO cardProgress
                        (cardId, direction, due, stability, difficulty, elapsedDays, scheduledDays,
                         reps, lapses, fsrsState, lastReview, learningSteps, createdAt, updatedAt)
                    SELECT id, '\(direction)', due, stability, difficulty, elapsedDays, scheduledDays,
                           reps, lapses, fsrsState, lastReview, learningSteps, createdAt, updatedAt
                    FROM card
                    """)
            }

            // Rebuild card table without FSRS columns (SQLite requires table rebuild for DROP COLUMN)
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.create(table: "card_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("deckId", .integer).notNull().references("deck", onDelete: .cascade)
                t.column("sourceValue", .text).notNull().defaults(to: "")
                t.column("targetValue", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
            try db.execute(sql: """
                INSERT INTO card_new (id, deckId, sourceValue, targetValue, createdAt, updatedAt, deletedAt)
                SELECT id, deckId, sourceValue, targetValue, createdAt, updatedAt, deletedAt
                FROM card
                """)
            try db.drop(table: "card")
            try db.rename(table: "card_new", to: "card")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        migrator.registerMigration("v6_study_mode_and_audio_play_count") { db in
            // SQLite requires a table rebuild to rename a column
            try db.execute(sql: "PRAGMA foreign_keys = OFF")
            try db.create(table: "reviewEvent_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cardId", .integer).notNull().references("card", onDelete: .cascade)
                t.column("rating", .integer).notNull()
                t.column("studyMode", .text).notNull().defaults(to: "reading")
                t.column("direction", .text).notNull()
                t.column("audioPlayCount", .integer).notNull().defaults(to: 0)
                t.column("playbackSpeed", .double).notNull().defaults(to: 1.0)
                t.column("timeToRevealSeconds", .double).notNull()
                t.column("timestamp", .datetime).notNull()
            }
            try db.execute(sql: """
                INSERT INTO reviewEvent_new
                    (id, cardId, rating, studyMode, direction, audioPlayCount, playbackSpeed, timeToRevealSeconds, timestamp)
                SELECT id, cardId, rating, studyMode, direction, audioReplayCount, playbackSpeed, timeToRevealSeconds, timestamp
                FROM reviewEvent
            """)
            try db.drop(table: "reviewEvent")
            try db.rename(table: "reviewEvent_new", to: "reviewEvent")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        try migrator.migrate(writer)
    }
}
