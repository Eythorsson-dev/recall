import Foundation
import FSRSBridge

public struct StudyScheduler: Sendable {
    private let bridge = FSRSBridge()

    public init() {}

    public func schedule(card: Card, rating: Rating, now: Date = Date()) -> Card {
        let fields = bridge.schedule(fields: card.toFSRSFields(), ratingRaw: rating.rawValue, now: now)
        var updated = card
        updated.applyFSRSFields(fields)
        return updated
    }

    public func preview(card: Card, now: Date = Date()) -> [Rating: Card] {
        let previews = bridge.preview(fields: card.toFSRSFields(), now: now)
        var out: [Rating: Card] = [:]
        for (rawValue, fields) in previews {
            guard let rating = Rating(rawValue: rawValue) else { continue }
            var updated = card
            updated.applyFSRSFields(fields)
            out[rating] = updated
        }
        return out
    }
}
