import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

@Test func fetchAllExcludesSoftDeleted() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card1 = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    var card2 = Card(deckId: deck.id!, sourceValue: "дякую", targetValue: "thank you", deletedAt: Date())
    try repo.insert(&card1)
    try repo.insert(&card2)

    let all = try repo.fetchAll(deckId: deck.id!)
    #expect(all.count == 1)
    #expect(all[0].sourceValue == "привіт")
}

@Test func softDeleteSetsDeletedAt() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)
    #expect(card.deletedAt == nil)

    try repo.softDelete(&card)
    #expect(card.deletedAt != nil)

    let all = try repo.fetchAll(deckId: deck.id!)
    #expect(all.isEmpty)
}

@Test func updatePersistsChanges() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)

    card.targetValue = "hi"
    try repo.update(&card)

    let fetched = try repo.fetchById(card.id!)
    #expect(fetched?.targetValue == "hi")
}

@Test func insertCreatesProgressRowsForBothDirections() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    let progress = try progressRepo.fetchAll(forCard: card.id!)
    #expect(progress.count == 2)
    #expect(progress.map(\.direction).contains(.sourceToTarget))
    #expect(progress.map(\.direction).contains(.targetToSource))
}

@Test func insertDefaultsToWordKind() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    #expect(card.kind == .word)

    try repo.insert(&card)
    let fetched = try repo.fetchById(card.id!)
    #expect(fetched?.kind == .word)
}

@Test func kindRoundTripsForSentence() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card = Card(
        deckId: deck.id!,
        sourceValue: "Я люблю каву вранці",
        targetValue: "I love coffee in the morning",
        kind: .sentence
    )
    try repo.insert(&card)

    let fetched = try repo.fetchById(card.id!)
    #expect(fetched?.kind == .sentence)
    #expect(fetched?.sourceValue == "Я люблю каву вранці")
}

@Test func updatePersistsKindChange() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)

    card.kind = .sentence
    try repo.update(&card)

    let fetched = try repo.fetchById(card.id!)
    #expect(fetched?.kind == .sentence)
}

@Test func fetchAllByKindFiltersCorrectly() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var word1 = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello", kind: .word)
    var word2 = Card(deckId: deck.id!, sourceValue: "дякую", targetValue: "thank you", kind: .word)
    var sentence1 = Card(
        deckId: deck.id!,
        sourceValue: "Я люблю каву",
        targetValue: "I love coffee",
        kind: .sentence
    )
    var sentence2 = Card(
        deckId: deck.id!,
        sourceValue: "Доброго ранку",
        targetValue: "Good morning",
        kind: .sentence
    )
    try repo.insert(&word1)
    try repo.insert(&word2)
    try repo.insert(&sentence1)
    try repo.insert(&sentence2)

    let words = try repo.fetchAll(deckId: deck.id!, kind: .word)
    #expect(words.count == 2)
    #expect(words.allSatisfy { $0.kind == .word })

    let sentences = try repo.fetchAll(deckId: deck.id!, kind: .sentence)
    #expect(sentences.count == 2)
    #expect(sentences.allSatisfy { $0.kind == .sentence })
}

@Test func fetchAllByKindExcludesSoftDeleted() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    var sentence = Card(
        deckId: deck.id!,
        sourceValue: "Я люблю каву",
        targetValue: "I love coffee",
        kind: .sentence,
        deletedAt: Date()
    )
    try repo.insert(&sentence)

    let sentences = try repo.fetchAll(deckId: deck.id!, kind: .sentence)
    #expect(sentences.isEmpty)
}

@Test func insertAllPersistsEveryCardAndCreatesProgressRows() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)

    var cards: [Card] = [
        Card(deckId: deck.id!, sourceValue: "I love coffee", targetValue: "Я люблю каву", kind: .sentence),
        Card(deckId: deck.id!, sourceValue: "coffee", targetValue: "кава", kind: .word),
        Card(deckId: deck.id!, sourceValue: "morning", targetValue: "ранок", kind: .word),
    ]
    try repo.insertAll(&cards)

    #expect(cards.allSatisfy { $0.id != nil })
    let allInDeck = try repo.fetchAll(deckId: deck.id!)
    #expect(allInDeck.count == 3)
    // Each card should have both standard CardProgress rows.
    for card in cards {
        let progress = try progressRepo.fetchAll(forCard: card.id!)
        #expect(progress.count == 2)
        #expect(Set(progress.map(\.direction)) == [.sourceToTarget, .targetToSource])
    }
}

@Test func insertAllRollsBackWhenAnyCardFails() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardRepository(database: db)

    // The second card has a non-existent deckId — FK violation rolls back the
    // whole batch. Neither card should land.
    var cards: [Card] = [
        Card(deckId: deck.id!, sourceValue: "first", targetValue: "перший", kind: .sentence),
        Card(deckId: 99_999, sourceValue: "bad", targetValue: "погано", kind: .word),
    ]

    var caught: Error?
    do {
        try repo.insertAll(&cards)
    } catch {
        caught = error
    }
    #expect(caught != nil)

    let allInDeck = try repo.fetchAll(deckId: deck.id!)
    #expect(allInDeck.isEmpty, "no card from the batch should have persisted after rollback")
}

@Test func v8MigrationExistingRowsDefaultToWordKind() throws {
    let db = try DatabaseManager.inMemory()
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try DeckRepository(database: db).insert(&deck)

    // Insert via raw SQL omitting kind — simulates pre-v8 rows during migration.
    try db.writer.write { dbConn in
        try dbConn.execute(
            sql: "INSERT INTO card (deckId, sourceValue, targetValue, createdAt, updatedAt) VALUES (?, 'привіт', 'hello', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
            arguments: [deck.id!]
        )
    }
    let cards = try db.reader.read { try Card.fetchAll($0) }
    #expect(cards[0].kind == .word)
}
