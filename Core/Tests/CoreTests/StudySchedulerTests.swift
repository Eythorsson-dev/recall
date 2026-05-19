import Testing
import Foundation
import FSRS
@testable import Core

@Test func scheduleNewCardWithGoodRating() throws {
    let scheduler = StudyScheduler()
    let card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")

    let updated = try scheduler.schedule(card: card, rating: .good)
    #expect(updated.reps == 1)
    #expect(updated.fsrsState != 0)
    #expect(updated.stability > 0)
    #expect(updated.due > card.due)
}

@Test func scheduleNewCardWithAgainKeepsLearning() throws {
    let scheduler = StudyScheduler()
    let card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")

    let updated = try scheduler.schedule(card: card, rating: .again)
    #expect(updated.reps == 1)
    #expect(updated.lapses == 1)
}

@Test func previewReturnsFourOptions() throws {
    let scheduler = StudyScheduler()
    let card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")

    let previews = try scheduler.preview(card: card)
    #expect(previews.count == 4)
    #expect(previews[.again] != nil)
    #expect(previews[.hard] != nil)
    #expect(previews[.good] != nil)
    #expect(previews[.easy] != nil)
}

@Test func easyRatingGivesLongerInterval() throws {
    let scheduler = StudyScheduler()
    let card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")

    let good = try scheduler.schedule(card: card, rating: .good)
    let easy = try scheduler.schedule(card: card, rating: .easy)
    #expect(easy.due >= good.due)
}
