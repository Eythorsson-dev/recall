import Testing
import Foundation
@testable import Core

private func makeDeck(in db: DatabaseManager, name: String = "Test") throws -> Deck {
    var deck = Deck(name: name, sourceLanguage: .english, targetLanguage: .ukrainian)
    try DeckRepository(database: db).insert(&deck)
    return deck
}

private func insertWord(
    deckId: Int64,
    source: String,
    target: String,
    in db: DatabaseManager,
    kind: CardKind = .word,
    deletedAt: Date? = nil
) throws -> Card {
    let repo = CardRepository(database: db)
    var card = Card(
        deckId: deckId,
        sourceValue: source,
        targetValue: target,
        kind: kind,
        deletedAt: deletedAt
    )
    try repo.insert(&card)
    return card
}

private func setFSRSState(
    cardId: Int64,
    direction: StudyDirection,
    state: Int,
    in db: DatabaseManager
) throws {
    let repo = CardProgressRepository(database: db)
    var p = try repo.fetch(cardId: cardId, direction: direction)!
    p.fsrsState = state
    try repo.update(&p)
}

@Suite(.serialized)
struct KnownVocabularyQueryTests {
    @Test func includesWordsWithFsrsStateAtLeastTwo() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let card = try insertWord(deckId: deck.id!, source: "coffee", target: "кава", in: db)
        try setFSRSState(cardId: card.id!, direction: .sourceToTarget, state: 2, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.count == 1)
        #expect(entries[0].source == "coffee")
        #expect(entries[0].target == "кава")
    }

    @Test func excludesWordsBelowStateTwo() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        // Default progress rows have fsrsState = 0 (new). No update needed.
        _ = try insertWord(deckId: deck.id!, source: "coffee", target: "кава", in: db)
        let card2 = try insertWord(deckId: deck.id!, source: "tea", target: "чай", in: db)
        try setFSRSState(cardId: card2.id!, direction: .sourceToTarget, state: 1, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.isEmpty)
    }

    @Test func eitherDirectionAtStateTwoSuffices() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let learnedSource = try insertWord(deckId: deck.id!, source: "coffee", target: "кава", in: db)
        let learnedTarget = try insertWord(deckId: deck.id!, source: "tea", target: "чай", in: db)

        try setFSRSState(cardId: learnedSource.id!, direction: .sourceToTarget, state: 2, in: db)
        try setFSRSState(cardId: learnedTarget.id!, direction: .targetToSource, state: 2, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.count == 2)
        let sources = entries.map(\.source)
        #expect(sources.contains("coffee"))
        #expect(sources.contains("tea"))
    }

    @Test func higherStatesAreIncluded() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let card = try insertWord(deckId: deck.id!, source: "coffee", target: "кава", in: db)
        // 3 = relearning, still >= 2
        try setFSRSState(cardId: card.id!, direction: .sourceToTarget, state: 3, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.count == 1)
    }

    @Test func excludesSentenceKindEvenWhenLearned() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let sentence = try insertWord(
            deckId: deck.id!,
            source: "I love coffee",
            target: "Я люблю каву",
            in: db,
            kind: .sentence
        )
        try setFSRSState(cardId: sentence.id!, direction: .sourceToTarget, state: 2, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.isEmpty)
    }

    @Test func excludesSoftDeletedCards() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let card = try insertWord(
            deckId: deck.id!,
            source: "coffee",
            target: "кава",
            in: db,
            deletedAt: Date()
        )
        try setFSRSState(cardId: card.id!, direction: .sourceToTarget, state: 2, in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.isEmpty)
    }

    @Test func scopesToSpecifiedDeck() throws {
        let db = try DatabaseManager.inMemory()
        let deckA = try makeDeck(in: db, name: "A")
        let deckB = try makeDeck(in: db, name: "B")

        let cardA = try insertWord(deckId: deckA.id!, source: "coffee", target: "кава", in: db)
        let cardB = try insertWord(deckId: deckB.id!, source: "tea", target: "чай", in: db)
        try setFSRSState(cardId: cardA.id!, direction: .sourceToTarget, state: 2, in: db)
        try setFSRSState(cardId: cardB.id!, direction: .sourceToTarget, state: 2, in: db)

        let entriesA = try KnownVocabularyQuery(database: db).fetch(deckId: deckA.id!)
        #expect(entriesA.count == 1)
        #expect(entriesA[0].source == "coffee")

        let entriesB = try KnownVocabularyQuery(database: db).fetch(deckId: deckB.id!)
        #expect(entriesB.count == 1)
        #expect(entriesB[0].source == "tea")
    }

    @Test func returnsEmptyForDeckWithNoLearnedWords() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        _ = try insertWord(deckId: deck.id!, source: "coffee", target: "кава", in: db)

        let entries = try KnownVocabularyQuery(database: db).fetch(deckId: deck.id!)
        #expect(entries.isEmpty)
    }
}
