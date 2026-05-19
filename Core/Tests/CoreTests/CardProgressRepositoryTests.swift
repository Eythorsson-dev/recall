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
    let now = Date()

    var card1 = Card(deckId: deck.id!, sourceValue: "так", targetValue: "yes")
    var card2 = Card(deckId: deck.id!, sourceValue: "ні", targetValue: "no")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)

    // Make card1 sourceToTarget overdue, leave everything else in the future
    var progress = try repo.fetch(cardId: card1.id!, direction: .sourceToTarget)!
    progress.due = now.addingTimeInterval(-3600)
    try repo.update(&progress)

    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: now)
    #expect(due.count == 1)
    #expect(due[0].cardId == card1.id!)
    #expect(due[0].direction == .sourceToTarget)
}

@Test func siblingSuppressionKeepsMoreOverdueDirection() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let now = Date()

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Make targetToSource more overdue than sourceToTarget
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
    s.due = now.addingTimeInterval(-3600)
    t.due = now.addingTimeInterval(-7200)
    try db.writer.write { dbConn in
        try s.update(dbConn)
        try t.update(dbConn)
    }

    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: nil, before: Date())
    #expect(due.count == 1)
    #expect(due[0].direction == .targetToSource)
}

@Test func siblingSuppressionTiebreakerPrefersSourceToTarget() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let repo = CardProgressRepository(database: db)
    let cardRepo = CardRepository(database: db)
    let dueDate = Date().addingTimeInterval(-3600)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Both directions have the exact same due date
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
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
    let now = Date()

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try cardRepo.insert(&card)

    // Make both directions overdue
    var s = try repo.fetch(cardId: card.id!, direction: .sourceToTarget)!
    var t = try repo.fetch(cardId: card.id!, direction: .targetToSource)!
    s.due = now.addingTimeInterval(-3600)
    t.due = now.addingTimeInterval(-7200)
    try repo.update(&s)
    try repo.update(&t)

    // Filtering by a specific direction should return only that direction, no suppression
    let due = try repo.fetchDueForSession(deckIds: [deck.id!], direction: .sourceToTarget, before: now)
    #expect(due.count == 1)
    #expect(due[0].direction == .sourceToTarget)
}
