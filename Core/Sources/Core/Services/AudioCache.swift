import Foundation
import CryptoKit

/// Content-addressed audio file store. Keys are `SHA256(text + language + voiceID)`.
/// Backed by a flat directory on disk; identical text/voice across cards dedupes naturally.
public final class AudioCache: @unchecked Sendable {
    public static let directoryName = "AudioCache"

    private let directory: URL
    private let fileManager: FileManager

    public init(directory: URL, fileManager: FileManager = .default) throws {
        self.directory = directory
        self.fileManager = fileManager
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Convenience: cache lives under the app's documents directory by default.
    public convenience init(fileManager: FileManager = .default) throws {
        let docs = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        try self.init(directory: docs.appending(path: Self.directoryName), fileManager: fileManager)
    }

    /// SHA256 hash of `text + language code + voiceID`. Stable, content-addressable cache key.
    public static func key(text: String, language: Language, voiceID: String) -> String {
        let payload = text + language.rawValue + voiceID
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func contains(_ key: String) -> Bool {
        fileManager.fileExists(atPath: url(forKey: key).path())
    }

    public func url(forKey key: String) -> URL {
        directory.appending(path: key)
    }

    /// Writes audio data for `key`. Idempotent — re-storing the same key overwrites in place.
    public func store(_ data: Data, forKey key: String) throws {
        try data.write(to: url(forKey: key), options: .atomic)
    }

    public func retrieve(forKey key: String) -> Data? {
        let path = url(forKey: key)
        guard fileManager.fileExists(atPath: path.path()) else { return nil }
        return try? Data(contentsOf: path)
    }

    /// Removes any file in the cache directory whose name is not present in `referencedKeys`.
    @discardableResult
    public func orphanSweep(referencedKeys: Set<String>) throws -> Int {
        let entries = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        var removed = 0
        for entry in entries where !referencedKeys.contains(entry.lastPathComponent) {
            try fileManager.removeItem(at: entry)
            removed += 1
        }
        return removed
    }
}
