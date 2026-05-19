import Foundation
import FSRSBridge

public struct StudyScheduler: Sendable {
    private let bridge = FSRSBridge()

    public init() {}

    public func schedule(progress: CardProgress, rating: Rating, now: Date = Date()) -> CardProgress {
        let fields = bridge.schedule(fields: progress.toFSRSFields(), ratingRaw: rating.rawValue, now: now)
        var updated = progress
        updated.applyFSRSFields(fields)
        return updated
    }

    public func preview(progress: CardProgress, now: Date = Date()) -> [Rating: CardProgress] {
        let previews = bridge.preview(fields: progress.toFSRSFields(), now: now)
        var out: [Rating: CardProgress] = [:]
        for (rawValue, fields) in previews {
            guard let rating = Rating(rawValue: rawValue) else { continue }
            var updated = progress
            updated.applyFSRSFields(fields)
            out[rating] = updated
        }
        return out
    }
}
