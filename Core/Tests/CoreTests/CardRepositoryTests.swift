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
