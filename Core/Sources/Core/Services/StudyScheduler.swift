import Foundation
import FSRS

public struct StudyScheduler: Sendable {
    private let fsrs: FSRS

    public init(parameters: FSRSParameters = FSRSParameters()) {
        self.fsrs = FSRS(parameters: parameters)
    }

    public func schedule(card: Card, rating: Rating, now: Date = Date()) throws -> Card {
        let fsrsCard = card.toFSRSCard()
        let result = try fsrs.next(card: fsrsCard, now: now, grade: rating)
        var updated = card
        updated.applyFSRS(result.card)
        return updated
    }

    public func preview(card: Card, now: Date = Date()) throws -> [Rating: Card] {
        let fsrsCard = card.toFSRSCard()
        let results = try fsrs.repeat(card: fsrsCard, now: now)
        var previews: [Rating: Card] = [:]
        for rating in [Rating.again, .hard, .good, .easy] {
            if let item = results[rating] {
                var updated = card
                updated.applyFSRS(item.card)
                previews[rating] = updated
            }
        }
        return previews
    }
}
