import FSRS
import Foundation

/// Primitive representation of an FSRS card's scheduling fields.
/// Used to cross the module boundary without exposing FSRS types.
public struct FSRSFields {
    public var due: Date
    public var stability: Double
    public var difficulty: Double
    public var elapsedDays: Double
    public var scheduledDays: Double
    public var reps: Int
    public var lapses: Int
    public var statusRaw: Int   // 0=new 1=learning 2=review 3=relearning
    public var lastReview: Date

    public init(
        due: Date, stability: Double, difficulty: Double,
        elapsedDays: Double, scheduledDays: Double,
        reps: Int, lapses: Int, statusRaw: Int, lastReview: Date
    ) {
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reps = reps
        self.lapses = lapses
        self.statusRaw = statusRaw
        self.lastReview = lastReview
    }
}

public struct FSRSBridge {
    private let fsrs: FSRS

    public init() {
        self.fsrs = FSRS(p: Params())
    }

    /// Computes the next scheduling state given a rating (1=again 2=hard 3=good 4=easy).
    public func schedule(fields: FSRSFields, ratingRaw: Int, now: Date) -> FSRSFields {
        guard let rating = Rating(rawValue: ratingRaw) else { return fields }
        let card = Card(
            due: fields.due,
            stability: fields.stability,
            difficulty: fields.difficulty,
            elapsedDays: fields.elapsedDays,
            scheduledDays: fields.scheduledDays,
            reps: fields.reps,
            lapses: fields.lapses,
            status: statusFromInt(fields.statusRaw),
            lastReview: fields.lastReview
        )
        let results = fsrs.repeat(card: card, now: now)
        guard let result = results[rating] else { return fields }
        return toFields(result.card)
    }

    /// Returns previews for all four ratings.
    public func preview(fields: FSRSFields, now: Date) -> [Int: FSRSFields] {
        let card = Card(
            due: fields.due,
            stability: fields.stability,
            difficulty: fields.difficulty,
            elapsedDays: fields.elapsedDays,
            scheduledDays: fields.scheduledDays,
            reps: fields.reps,
            lapses: fields.lapses,
            status: statusFromInt(fields.statusRaw),
            lastReview: fields.lastReview
        )
        let results = fsrs.repeat(card: card, now: now)
        var out: [Int: FSRSFields] = [:]
        for (rating, info) in results {
            out[rating.rawValue] = toFields(info.card)
        }
        return out
    }

    private func toFields(_ card: Card) -> FSRSFields {
        FSRSFields(
            due: card.due,
            stability: card.stability,
            difficulty: card.difficulty,
            elapsedDays: card.elapsedDays,
            scheduledDays: card.scheduledDays,
            reps: card.reps,
            lapses: card.lapses,
            statusRaw: statusToInt(card.status),
            lastReview: card.lastReview
        )
    }

    private func statusFromInt(_ i: Int) -> Status {
        switch i {
        case 1: return .learning
        case 2: return .review
        case 3: return .relearning
        default: return .new
        }
    }

    private func statusToInt(_ s: Status) -> Int {
        switch s {
        case .new: return 0
        case .learning: return 1
        case .review: return 2
        case .relearning: return 3
        }
    }
}
