import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

@Test func reviewEventInsertAndFetch() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    var event = ReviewEvent(
        cardId: card.id!,
        rating: 3,
        direction: .sourceToTarget,
        timeToRevealSeconds: 2.5
    )
    try eventRepo.insert(&event)
    #expect(event.id != nil)

    let events = try eventRepo.fetchAll(forCard: card.id!)
    #expect(events.count == 1)
    #expect(events[0].rating == 3)
    #expect(events[0].timeToRevealSeconds == 2.5)
    #expect(events[0].studyMode == "reading")
}

@Test func reviewEventCascadesOnCardDelete() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    var event = ReviewEvent(cardId: card.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    try eventRepo.insert(&event)

    try db.writer.write { dbConn in
        _ = try Card.deleteAll(dbConn)
    }

    let events = try eventRepo.fetchAll(forCard: card.id!)
    #expect(events.isEmpty)
}
