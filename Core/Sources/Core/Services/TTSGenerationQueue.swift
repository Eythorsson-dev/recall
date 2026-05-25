import Foundation
import GRDB

/// Persistent, idempotent queue of pending audio-generation jobs.
///
/// Lifecycle of a job:
/// 1. `enqueue` — if the cache already holds audio for `(text, language)`, the card's
///    audio key column is populated immediately and no job is inserted.
/// 2. `processPending` — for each pending or failed job: generate audio via the
///    injected `TTSService`, write to `AudioCache`, update the card's audio key,
///    and delete the job row. On failure the job is kept with `status = failed`
///    so a later `processPending()` retries it.
public final class TTSGenerationQueue: Sendable {
    private let database: DatabaseManager
    private let cache: AudioCache
    private let tts: TTSService

    public init(database: DatabaseManager, cache: AudioCache, tts: TTSService) {
        self.database = database
        self.cache = cache
        self.tts = tts
    }

    /// Enqueues generation of `text` for `card`'s `fieldSide`.
    /// Idempotent — no-op if the audio is already cached, and a unique
    /// `(cardId, fieldSide)` index collapses duplicate enqueues into one job.
    public func enqueue(
        cardId: Int64,
        fieldSide: FieldSide,
        text: String,
        language: Language,
        now: Date = Date()
    ) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = AudioCache.key(text: text, language: language, voiceID: language.defaultVoiceID)

        // Fast path: audio is already on disk → just stamp the card and we're done.
        if cache.contains(key) {
            try writeAudioKey(cardId: cardId, fieldSide: fieldSide, key: key)
            return
        }

        try database.writer.write { db in
            // Replace any prior row for this (card, fieldSide) so a re-enqueue
            // after a field edit picks up the new text in a single job.
            try db.execute(sql: """
                DELETE FROM ttsGenerationJob WHERE cardId = ? AND fieldSide = ?
                """, arguments: [cardId, fieldSide.rawValue])

            var job = TTSGenerationJob(
                cardId: cardId,
                fieldSide: fieldSide,
                text: text,
                language: language,
                status: .pending,
                createdAt: now
            )
            try job.insert(db)
        }
    }

    public func pendingCount() throws -> Int {
        try database.reader.read { db in
            try TTSGenerationJob.fetchCount(db)
        }
    }

    /// Generates audio for every pending and failed job, in insertion order.
    /// Safe to call repeatedly — finished jobs are deleted before the next iteration.
    public func processPending() async throws {
        let jobs = try await database.reader.read { db in
            try TTSGenerationJob
                .order(Column("createdAt").asc, Column("id").asc)
                .fetchAll(db)
        }

        for job in jobs {
            guard let jobId = job.id else { continue }

            let key = AudioCache.key(
                text: job.text,
                language: job.language,
                voiceID: job.language.defaultVoiceID
            )

            // Another job (or a manual fill) may have populated this key in the meantime —
            // skip the network call and just stamp the card.
            if cache.contains(key) {
                try writeAudioKey(cardId: job.cardId, fieldSide: job.fieldSide, key: key)
                try delete(jobId: jobId)
                continue
            }

            do {
                let data = try await tts.generate(text: job.text, language: job.language)
                try cache.store(data, forKey: key)
                try writeAudioKey(cardId: job.cardId, fieldSide: job.fieldSide, key: key)
                try delete(jobId: jobId)
            } catch {
                try markFailed(jobId: jobId)
            }
        }
    }

    private func writeAudioKey(cardId: Int64, fieldSide: FieldSide, key: String) throws {
        let column = (fieldSide == .source) ? "sourceAudioKey" : "targetAudioKey"
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE card SET \(column) = ?, updatedAt = ? WHERE id = ?",
                arguments: [key, Date(), cardId]
            )
        }
    }

    private func delete(jobId: Int64) throws {
        try database.writer.write { db in
            try db.execute(sql: "DELETE FROM ttsGenerationJob WHERE id = ?", arguments: [jobId])
        }
    }

    private func markFailed(jobId: Int64) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE ttsGenerationJob SET status = ? WHERE id = ?",
                arguments: [TTSJobStatus.failed.rawValue, jobId]
            )
        }
    }
}
