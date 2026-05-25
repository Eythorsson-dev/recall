import Foundation

/// In-memory pending state for the Generation Review modal. Owns a mutable
/// list of `GeneratedSentence`s and computes the active set of new vocabulary
/// words on demand — when the user swipes-to-delete a sentence, any new word
/// that was *only* introduced by that sentence is dropped from the batch; new
/// words still referenced by another pending sentence remain.
public struct PendingGenerationBatch: Sendable, Equatable {
    public private(set) var sentences: [GeneratedSentence]

    public init(sentences: [GeneratedSentence]) {
        self.sentences = sentences
    }

    /// Deduplicated union of `newWords` across every currently pending sentence,
    /// in first-occurrence order.
    public var activeNewWords: [NewWord] {
        var seen = Set<String>()
        var out: [NewWord] = []
        for sentence in sentences {
            for word in sentence.newWords where seen.insert(word.source).inserted {
                out.append(word)
            }
        }
        return out
    }

    public mutating func remove(at index: Int) {
        sentences.remove(at: index)
    }

    public mutating func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            sentences.remove(at: offset)
        }
    }

    /// Builds the flat list of `Card` rows that should be inserted on Accept.
    ///
    /// Sentence-cards come first (kind = .sentence). Then one word-card per
    /// `activeNewWord` (kind = .word). Each card adopts the deck's source/target
    /// language pair via the language convention below.
    ///
    /// Language convention bridge:
    /// - `NewWord.source` is in the deck's TARGET language (the word as it
    ///   appears inside the generated sentence — e.g. Ukrainian "каву").
    /// - `NewWord.target` is in the deck's SOURCE language (the translation
    ///   used to learn it — e.g. English "coffee").
    /// - `Card.sourceValue` holds the deck's SOURCE-language value; `targetValue`
    ///   holds the TARGET-language value. So we flip when materializing.
    public func materializeCards(deckId: Int64) -> [Card] {
        var cards: [Card] = sentences.map { sentence in
            Card(
                deckId: deckId,
                sourceValue: sentence.source,
                targetValue: sentence.target,
                targetValueIsUserModified: true,
                kind: .sentence
            )
        }
        for word in activeNewWords {
            cards.append(Card(
                deckId: deckId,
                sourceValue: word.target,
                targetValue: word.source,
                targetValueIsUserModified: true,
                kind: .word
            ))
        }
        return cards
    }
}
