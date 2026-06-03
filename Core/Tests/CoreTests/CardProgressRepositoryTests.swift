import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

private func insertCard(deckId: Int64, in db: DatabaseManager) throws -> Card {
    let repo = CardRepository(database: db)
    var card = Card(deckId: deckId, sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)
    return card
}

@Test func insertAndFetchBothDirections() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let card = try insertCard(deckId: deck.id!, in: db)
    let repo = CardProgressRepository(database: db)

    let all = try repo.fetchAll(forCard: card.id!)
    #expect(all.count == 2)
    #expect(all.map(\.direction).contains(.sourceToTarget))
    #expect(all.map(\.direction).contains(.targetToSource))
}

@Test func fetchSingleDirection() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let card = try insertCard(deckId: deck.id!, in: db)
    let repo = CardProgressRepository(database: db)

    let progress = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)
    #expect(progress != nil)
    #expect(progress?.direction == .sourceToTarget)
    #expect(progress?.cardId == card.id!)
}

@Test func updatePersistsSchedulingFields() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let card = try insertCard(deckId: deck.id!, in: db)
    let repo = CardProgressRepository(database: db)
    let scheduler = StudyScheduler()

    var progress = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    progress = scheduler.schedule(progress: progress, rating: .good)
    try repo.update(&progress)

    let fetched = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    #expect(fetched.reps == 1)
    #expect(fetched.stability > 0)
}

@Test func sessionQueueReturnsOnlyDueRows() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let scheduler = StudyScheduler()
    let now = Date()
    // cutoff is 30 min ago; only the explicitly-overdue row (1 hour ago) falls before it.
    let cutoff = now.addingTimeInterval(-1800)

    var card1 = Card(deckId: deck.id!, sourceValue: "так", targetValue: "yes")
    var card2 = Card(deckId: deck.id!, sourceValue: "ні", targetValue: "no")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)

    // Advance card1 past fsrsState 0, then backdate its due so it's overdue
    var progress = try repo.fetch(cardId: card1.id!, direction: .sourceToTarget)!
    progress = scheduler.schedule(progress: progress, rating: .good)
    progress.due = now.addingTimeInterval(-3600)
    try repo.update(&progress)

    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: cutoff)
    #expect(due.count == 1)
    #expect(due[0].cardId == card1.id!)
    #expect(due[0].direction == .sourceToTarget)
}

@Test func siblingSuppressionKeepsMoreOverdueDirection() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let scheduler = StudyScheduler()
    let now = Date()

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Advance both directions past fsrsState 0, then set different due dates
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
    s = scheduler.schedule(progress: s, rating: .good)
    t = scheduler.schedule(progress: t, rating: .good)
    // Make targetToSource more overdue than sourceToTarget
    s.due = now.addingTimeInterval(-3600)
    t.due = now.addingTimeInterval(-7200)
    try repo.update(&s)
    try repo.update(&t)

    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: Date())
    #expect(due.count == 1)
    #expect(due[0].direction == .targetToSource)
}

@Test func siblingSuppressionTiebreakerPrefersSourceToTarget() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let scheduler = StudyScheduler()
    let dueDate = Date().addingTimeInterval(-3600)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Advance both directions past fsrsState 0, then set the same due date
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
    s = scheduler.schedule(progress: s, rating: .good)
    t = scheduler.schedule(progress: t, rating: .good)
    s.due = dueDate
    t.due = dueDate
    try repo.update(&s)
    try repo.update(&t)

    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: Date())
    #expect(due.count == 1)
    #expect(due[0].direction == .sourceToTarget)
}

@Test func directionFilterSkipsSiblingSupression() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let scheduler = StudyScheduler()
    let now = Date()

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Advance both directions past fsrsState 0, then make both overdue
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
    s = scheduler.schedule(progress: s, rating: .good)
    t = scheduler.schedule(progress: t, rating: .good)
    s.due = now.addingTimeInterval(-3600)
    t.due = now.addingTimeInterval(-7200)
    try repo.update(&s)
    try repo.update(&t)

    // Filtering by a specific direction should return only that direction, no suppression
    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: .sourceToTarget, before: now)
    #expect(due.count == 1)
    #expect(due[0].direction == .sourceToTarget)
}

@Test func fetchDueForSessionExcludesNewCards() throws {
    // Regression: new cards (fsrsState == 0) have due = createdAt (past), so they satisfied
    // fetchDueForSession's "due <= now" filter and also fetchNewCards's "fsrsState == 0" filter,
    // causing the same card+direction to appear twice in the interleaved queue.
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // New card: fsrsState == 0, due date is in the past (the default)
    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: Date())
    #expect(due.isEmpty, "new cards must not appear in the due queue")

    let newCards = try repo.fetchNewCards(deckIds: [deck.id!], direction: nil, limit: 10)
    #expect(newCards.count == 2) // both directions
}

@Test func fetchNewCardsReturnsOnlyFsrsStateZero() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let scheduler = StudyScheduler()

    var card1 = Card(deckId: deck.id!, sourceValue: "так", targetValue: "yes")
    var card2 = Card(deckId: deck.id!, sourceValue: "ні", targetValue: "no")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)

    // Rate card1 so it's no longer in fsrsState 0
    var p = try repo.fetch(cardId: card1.id!, direction: .sourceToTarget)!
    p = scheduler.schedule(progress: p, rating: .good)
    try repo.update(&p)

    let newCards = try repo.fetchNewCards(deckIds: [deck.id!], direction: .sourceToTarget, limit: 10)
    #expect(newCards.count == 1)
    #expect(newCards[0].cardId == card2.id!)
}

@Test func fetchNewCardsRespectsLimit() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)

    for i in 0..<5 {
        var card = Card(deckId: deck.id!, sourceValue: "word\(i)", targetValue: "trans\(i)")
        try cardRepo.insert(&card)
    }

    let newCards = try repo.fetchNewCards(deckIds: [deck.id!], direction: .sourceToTarget, limit: 3)
    #expect(newCards.count == 3)
}

@Test func fetchNewCardsRespectsDirectionFilter() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    let forward = try repo.fetchNewCards(deckIds: [deck.id!], direction: .sourceToTarget, limit: 10)
    let reverse = try repo.fetchNewCards(deckIds: [deck.id!], direction: .targetToSource, limit: 10)
    #expect(forward.count == 1)
    #expect(forward[0].direction == .sourceToTarget)
    #expect(reverse.count == 1)
    #expect(reverse[0].direction == .targetToSource)
}
