import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

@Test func reviewEventRoundTripsAudioPlayCountAndStudyMode() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    var event = ReviewEvent(
        cardId: card.id!,
        rating: 3,
        studyMode: .listeningWithText,
        direction: .sourceToTarget,
        audioPlayCount: 4,
        timeToRevealSeconds: 2.5
    )
    try eventRepo.insert(&event)
    #expect(event.id != nil)

    let events = try eventRepo.fetchAll(forCard: card.id!)
    #expect(events.count == 1)
    #expect(events[0].rating == 3)
    #expect(events[0].studyMode == .listeningWithText)
    #expect(events[0].audioPlayCount == 4)
    #expect(events[0].timeToRevealSeconds == 2.5)
}

@Test func reviewEventPlaybackSpeedPersists() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    var event = ReviewEvent(cardId: card.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    try eventRepo.insert(&event)

    let events = try eventRepo.fetchAll(forCard: card.id!)
    #expect(events[0].playbackSpeed == 1.0)
}

@Test func reviewEventCascadesOnCardDelete() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    var event = ReviewEvent(cardId: card.id!, rating: 3, studyMode: .reading, direction: .sourceToTarget, audioPlayCount: 0, timeToRevealSeconds: 1.0)
    try eventRepo.insert(&event)

    try db.writer.write { dbConn in
        _ = try Card.deleteAll(dbConn)
    }

    let events = try eventRepo.fetchAll(forCard: card.id!)
    #expect(events.isEmpty)
}
