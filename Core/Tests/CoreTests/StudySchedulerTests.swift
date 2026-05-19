import Testing
import Foundation
import FSRS
@testable import Core

private func makeProgress(direction: StudyDirection = .sourceToTarget) throws -> CardProgress {
    let db = try DatabaseManager.inMemory()
    let deckRepo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try deckRepo.insert(&deck)
    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    let cardRepo = CardRepository(database: db)
    try cardRepo.insert(&card)
    return CardProgress(cardId: card.id!, direction: direction)
}

@Test func scheduleNewCardWithGoodRating() throws {
    let scheduler = StudyScheduler()
    let progress = try makeProgress()

    let updated = scheduler.schedule(progress: progress, rating: .good)
    #expect(updated.reps == 1)
    #expect(updated.fsrsState != 0)
    #expect(updated.stability > 0)
    #expect(updated.due > progress.due)
}

@Test func scheduleNewCardWithAgainKeepsLearning() throws {
    let scheduler = StudyScheduler()
    let progress = try makeProgress()

    let updated = scheduler.schedule(progress: progress, rating: .again)
    #expect(updated.reps == 1)
    #expect(updated.fsrsState == 1) // stays in Learning state; new cards don't count as lapses
}

@Test func previewReturnsFourOptions() throws {
    let scheduler = StudyScheduler()
    let progress = try makeProgress()

    let previews = scheduler.preview(progress: progress)
    #expect(previews.count == 4)
    #expect(previews[.again] != nil)
    #expect(previews[.hard] != nil)
    #expect(previews[.good] != nil)
    #expect(previews[.easy] != nil)
}

@Test func easyRatingGivesLongerInterval() throws {
    let scheduler = StudyScheduler()
    let progress = try makeProgress()

    let good = scheduler.schedule(progress: progress, rating: .good)
    let easy = scheduler.schedule(progress: progress, rating: .easy)
    #expect(easy.due >= good.due)
}
