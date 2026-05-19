import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

@Test func databaseOpensAndMigrates() throws {
    let db = try DatabaseManager.inMemory()
    let count = try db.reader.read { db in
        try Card.fetchCount(db)
    }
    #expect(count == 0)
}

@Test func deckInsertAndFetch() throws {
    let db = try DatabaseManager.inMemory()
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Ukrainian → English", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)

    let fetched = try repo.fetchAll()
    #expect(fetched.count == 1)
    #expect(fetched[0].sourceLanguage == .ukrainian)
    #expect(fetched[0].targetLanguage == .english)
}

@Test func cardInsertAndFetch() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    let cardRepo = CardRepository(database: db)
    try cardRepo.insert(&card)

    let fetched = try db.reader.read { dbConn in try Card.fetchAll(dbConn) }
    #expect(fetched.count == 1)
    #expect(fetched[0].sourceValue == "привіт")
    #expect(fetched[0].targetValue == "hello")
    #expect(fetched[0].deckId == deck.id!)
}

@Test func v5MigrationCreatesCardProgressRows() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    let progress = try progressRepo.fetchAll(forCard: card.id!)
    #expect(progress.count == 2)
    let directions = Set(progress.map(\.direction))
    #expect(directions == [.sourceToTarget, .targetToSource])
}
