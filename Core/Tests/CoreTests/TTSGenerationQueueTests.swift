import Testing
import Foundation
import GRDB
@testable import Core

private actor CallLog {
    private(set) var calls: [(text: String, language: Language)] = []
    func record(_ text: String, _ language: Language) { calls.append((text, language)) }
}

private struct MockTTSService: TTSService {
    let log: CallLog
    let payload: Data
    let shouldThrow: Bool

    func generate(text: String, language: Language) async throws -> Data {
        await log.record(text, language)
        if shouldThrow { throw MockError.boom }
        return payload
    }

    enum MockError: Error { case boom }
}

private func makeFixture(shouldThrow: Bool = false) throws -> (db: DatabaseManager, deck: Deck, card: Card, cache: AudioCache, cacheDir: URL, queue: TTSGenerationQueue, log: CallLog) {
    let db = try DatabaseManager.inMemory()
    var deck = Deck(name: "T", sourceLanguage: .ukrainian, targetLanguage: .english, sourceSpeakable: true, targetSpeakable: true)
    try DeckRepository(database: db).insert(&deck)
    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try CardRepository(database: db).insert(&card)

    let cacheDir = FileManager.default.temporaryDirectory.appending(path: "TTSQueueTests-\(UUID().uuidString)")
    let cache = try AudioCache(directory: cacheDir)
    let log = CallLog()
    let mock = MockTTSService(log: log, payload: Data("audio-bytes".utf8), shouldThrow: shouldThrow)
    let queue = TTSGenerationQueue(database: db, cache: cache, tts: mock)
    return (db, deck, card, cache, cacheDir, queue, log)
}

@Test func enqueueInsertsPendingJob() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)

    #expect(try f.queue.pendingCount() == 1)
}

@Test func enqueueSkipsWhenAudioAlreadyCached() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    // Pre-seed the cache with audio for this exact (text, language, voice) tuple.
    let key = AudioCache.key(text: "привіт", language: .ukrainian, voiceID: Language.ukrainian.defaultVoiceID)
    try f.cache.store(Data("prewritten".utf8), forKey: key)

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)

    #expect(try f.queue.pendingCount() == 0)
    // Card's source audio key was stamped without queueing a job.
    let fetched = try CardRepository(database: f.db).fetchById(f.card.id!)
    #expect(fetched?.sourceAudioKey == key)
}

@Test func enqueueIsIdempotentForSameCardAndField() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)
    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)

    #expect(try f.queue.pendingCount() == 1)
}

@Test func enqueueReplacesPriorJobWhenTextChanges() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "old", language: .ukrainian)
    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "new", language: .ukrainian)

    let jobs = try await f.db.reader.read { try TTSGenerationJob.fetchAll($0) }
    #expect(jobs.count == 1)
    #expect(jobs[0].text == "new")
}

@Test func processPendingGeneratesCachesAndStampsCard() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .target, text: "hello", language: .english)
    try await f.queue.processPending()

    let key = AudioCache.key(text: "hello", language: .english, voiceID: Language.english.defaultVoiceID)
    #expect(f.cache.contains(key))
    #expect(f.cache.retrieve(forKey: key) == Data("audio-bytes".utf8))

    let fetched = try CardRepository(database: f.db).fetchById(f.card.id!)
    #expect(fetched?.targetAudioKey == key)
    #expect(try f.queue.pendingCount() == 0)

    let callCount = await f.log.calls.count
    #expect(callCount == 1)
}

@Test func processPendingIsIdempotent() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)
    try await f.queue.processPending()
    try await f.queue.processPending()

    let callCount = await f.log.calls.count
    #expect(callCount == 1) // no double-generation
}

@Test func failedJobsRemainInQueueWithStatusFailed() async throws {
    let f = try makeFixture(shouldThrow: true)
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)
    try await f.queue.processPending()

    let jobs = try await f.db.reader.read { try TTSGenerationJob.fetchAll($0) }
    #expect(jobs.count == 1)
    #expect(jobs[0].status == .failed)

    let fetched = try CardRepository(database: f.db).fetchById(f.card.id!)
    #expect(fetched?.sourceAudioKey == nil)
}

@Test func failedJobsAreRetriedOnNextProcessPending() async throws {
    // Start failing; switch to a passing service for the retry.
    let db = try DatabaseManager.inMemory()
    var deck = Deck(name: "T", sourceLanguage: .ukrainian, targetLanguage: .english, sourceSpeakable: true)
    try DeckRepository(database: db).insert(&deck)
    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "")
    try CardRepository(database: db).insert(&card)

    let cacheDir = FileManager.default.temporaryDirectory.appending(path: "TTSQueueRetry-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: cacheDir) }
    let cache = try AudioCache(directory: cacheDir)

    let log = CallLog()
    let failingQueue = TTSGenerationQueue(
        database: db,
        cache: cache,
        tts: MockTTSService(log: log, payload: Data(), shouldThrow: true)
    )
    try failingQueue.enqueue(cardId: card.id!, fieldSide: .source, text: "привіт", language: .ukrainian)
    try await failingQueue.processPending()

    let workingQueue = TTSGenerationQueue(
        database: db,
        cache: cache,
        tts: MockTTSService(log: log, payload: Data("ok".utf8), shouldThrow: false)
    )
    try await workingQueue.processPending()

    #expect(try workingQueue.pendingCount() == 0)
    let fetched = try CardRepository(database: db).fetchById(card.id!)
    #expect(fetched?.sourceAudioKey != nil)
}

@Test func enqueueIgnoresEmptyAndWhitespaceText() async throws {
    let f = try makeFixture()
    defer { try? FileManager.default.removeItem(at: f.cacheDir) }

    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .source, text: "", language: .english)
    try f.queue.enqueue(cardId: f.card.id!, fieldSide: .target, text: "   \n", language: .english)

    #expect(try f.queue.pendingCount() == 0)
}
