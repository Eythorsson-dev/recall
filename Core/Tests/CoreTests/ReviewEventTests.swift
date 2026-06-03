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

@Test func partialSessionPersistsRatedCards() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)
    let scheduler = StudyScheduler()

    var card1 = Card(deckId: deck.id!, sourceValue: "так", targetValue: "yes")
    var card2 = Card(deckId: deck.id!, sourceValue: "ні", targetValue: "no")
    var card3 = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)
    try cardRepo.insert(&card3)

    // Advance all three sourceToTarget rows past fsrsState 0 via a real scheduling step,
    // then backdate their due so they appear in the queue.
    let dueDate = Date().addingTimeInterval(-3600)
    for card in [card1, card2, card3] {
        var p = try progressRepo.fetch(cardId: card.id!, direction: .sourceToTarget)!
        p = scheduler.schedule(progress: p, rating: .good)
        p.due = dueDate
        try progressRepo.update(&p)
    }

    let queue = try progressRepo.fetchDueForSession(
        deckIds: [deck.id!],
        direction: .sourceToTarget
    )
    #expect(queue.count == 3)

    // Snapshot untouched cards' state before the session
    let untouchedIds = queue.dropFirst().map(\.cardId)
    var preSessionReps: [Int64: Int] = [:]
    var preSessionStability: [Int64: Double] = [:]
    for id in untouchedIds {
        let p = try progressRepo.fetch(cardId: id, direction: .sourceToTarget)!
        preSessionReps[id] = p.reps
        preSessionStability[id] = p.stability
    }

    // Replay StudySessionView.rateCard for the first card only, then "abort".
    let first = queue[0]
    let now = Date()
    var updated = scheduler.schedule(progress: first, rating: .good, now: now)
    try progressRepo.update(&updated)

    var event = ReviewEvent(
        cardId: first.cardId,
        rating: Int(Rating.good.rawValue),
        studyMode: .reading,
        direction: first.direction,
        timeToRevealSeconds: 1.5
    )
    try eventRepo.insert(&event)

    // Rated card: exactly one event + stats advanced beyond the pre-session state.
    let firstEvents = try eventRepo.fetchAll(forCard: first.cardId)
    #expect(firstEvents.count == 1)
    #expect(firstEvents[0].rating == Int(Rating.good.rawValue))
    #expect(firstEvents[0].direction == .sourceToTarget)

    let firstProgress = try progressRepo.fetch(cardId: first.cardId, direction: .sourceToTarget)!
    #expect(firstProgress.reps == 2)
    #expect(firstProgress.stability > 0)
    #expect(firstProgress.lastReview != nil)

    // Untouched cards: no events, reps/stability unchanged from before the session.
    for id in untouchedIds {
        let events = try eventRepo.fetchAll(forCard: id)
        #expect(events.isEmpty)
        let p = try progressRepo.fetch(cardId: id, direction: .sourceToTarget)!
        #expect(p.reps == preSessionReps[id])
        #expect(p.stability == preSessionStability[id])
    }
}

@Test func fetchTodayNewCardCountCountsFirstReviewsToday() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var card1 = Card(deckId: deck.id!, sourceValue: "так", targetValue: "yes")
    var card2 = Card(deckId: deck.id!, sourceValue: "ні", targetValue: "no")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)

    // card1: first reviewed today (two events today → still counts as 1)
    var e1 = ReviewEvent(cardId: card1.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    var e2 = ReviewEvent(cardId: card1.id!, rating: 4, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    try eventRepo.insert(&e1)
    try eventRepo.insert(&e2)

    // card2: first reviewed yesterday → does not count
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    var e3 = ReviewEvent(cardId: card2.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0, timestamp: yesterday)
    try eventRepo.insert(&e3)

    let count = try eventRepo.fetchTodayNewCardCount(deckIds: [deck.id!])
    #expect(count == 1)
}

@Test func fetchTodayNewCardCountIgnoresCardsFromOtherDecks() throws {
    let db = try DatabaseManager.inMemory()
    let deckRepo = DeckRepository(database: db)
    var deckA = Deck(name: "A", sourceLanguage: .ukrainian, targetLanguage: .english)
    var deckB = Deck(name: "B", sourceLanguage: .ukrainian, targetLanguage: .english)
    try deckRepo.insert(&deckA)
    try deckRepo.insert(&deckB)

    let cardRepo = CardRepository(database: db)
    let eventRepo = ReviewEventRepository(database: db)

    var cardA = Card(deckId: deckA.id!, sourceValue: "так", targetValue: "yes")
    var cardB = Card(deckId: deckB.id!, sourceValue: "ні", targetValue: "no")
    try cardRepo.insert(&cardA)
    try cardRepo.insert(&cardB)

    var eA = ReviewEvent(cardId: cardA.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    var eB = ReviewEvent(cardId: cardB.id!, rating: 3, direction: .sourceToTarget, timeToRevealSeconds: 1.0)
    try eventRepo.insert(&eA)
    try eventRepo.insert(&eB)

    let count = try eventRepo.fetchTodayNewCardCount(deckIds: [deckA.id!])
    #expect(count == 1)
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
