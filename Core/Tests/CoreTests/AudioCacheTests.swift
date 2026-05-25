import Testing
import Foundation
@testable import Core

private func makeTempCache() throws -> (AudioCache, URL) {
    let dir = FileManager.default.temporaryDirectory.appending(path: "AudioCacheTests-\(UUID().uuidString)")
    let cache = try AudioCache(directory: dir)
    return (cache, dir)
}

@Test func storeAndRetrieveRoundTrip() throws {
    let (cache, dir) = try makeTempCache()
    defer { try? FileManager.default.removeItem(at: dir) }

    let key = AudioCache.key(text: "hello", language: .english, voiceID: Language.english.defaultVoiceID)
    let data = Data("audio".utf8)

    try cache.store(data, forKey: key)
    #expect(cache.contains(key))
    #expect(cache.retrieve(forKey: key) == data)
}

@Test func retrieveMissingKeyReturnsNil() throws {
    let (cache, dir) = try makeTempCache()
    defer { try? FileManager.default.removeItem(at: dir) }

    let key = AudioCache.key(text: "never-stored", language: .english, voiceID: "v")
    #expect(cache.retrieve(forKey: key) == nil)
    #expect(!cache.contains(key))
}

@Test func storingSameKeyTwiceIsSafe() throws {
    let (cache, dir) = try makeTempCache()
    defer { try? FileManager.default.removeItem(at: dir) }

    let key = AudioCache.key(text: "hi", language: .english, voiceID: "v")
    try cache.store(Data("first".utf8), forKey: key)
    try cache.store(Data("second".utf8), forKey: key)

    #expect(cache.retrieve(forKey: key) == Data("second".utf8))
}

@Test func orphanSweepRemovesOnlyUnreferencedFiles() throws {
    let (cache, dir) = try makeTempCache()
    defer { try? FileManager.default.removeItem(at: dir) }

    let keep1 = AudioCache.key(text: "alpha", language: .english, voiceID: "v")
    let keep2 = AudioCache.key(text: "beta", language: .ukrainian, voiceID: "v")
    let orphan = AudioCache.key(text: "gamma", language: .norwegian, voiceID: "v")

    try cache.store(Data("a".utf8), forKey: keep1)
    try cache.store(Data("b".utf8), forKey: keep2)
    try cache.store(Data("c".utf8), forKey: orphan)

    let removed = try cache.orphanSweep(referencedKeys: [keep1, keep2])

    #expect(removed == 1)
    #expect(cache.contains(keep1))
    #expect(cache.contains(keep2))
    #expect(!cache.contains(orphan))
}

@Test func keyIsStableAcrossCalls() {
    let k1 = AudioCache.key(text: "Привіт", language: .ukrainian, voiceID: "uk-UA-Wavenet-A")
    let k2 = AudioCache.key(text: "Привіт", language: .ukrainian, voiceID: "uk-UA-Wavenet-A")
    #expect(k1 == k2)
    #expect(k1.count == 64) // SHA-256 hex digest
}

@Test func keyVariesByTextLanguageAndVoice() {
    let base = AudioCache.key(text: "hi", language: .english, voiceID: "v1")
    #expect(base != AudioCache.key(text: "bye", language: .english, voiceID: "v1"))
    #expect(base != AudioCache.key(text: "hi", language: .ukrainian, voiceID: "v1"))
    #expect(base != AudioCache.key(text: "hi", language: .english, voiceID: "v2"))
}
