import Testing
import Foundation
@testable import Core

@Test func fetchAllExcludesSoftDeleted() throws {
    let db = try DatabaseManager.inMemory()
    let repo = CardRepository(database: db)

    var card1 = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")
    var card2 = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "дякую", targetValue: "thank you", deletedAt: Date())
    try repo.insert(&card1)
    try repo.insert(&card2)

    let all = try repo.fetchAll()
    #expect(all.count == 1)
    #expect(all[0].sourceValue == "привіт")
}

@Test func fetchDueReturnsOnlyDueCards() throws {
    let db = try DatabaseManager.inMemory()
    let repo = CardRepository(database: db)
    let now = Date()

    var dueCard = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "так", targetValue: "yes", due: now.addingTimeInterval(-3600))
    var futureCard = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "ні", targetValue: "no", due: now.addingTimeInterval(86400))
    try repo.insert(&dueCard)
    try repo.insert(&futureCard)

    let due = try repo.fetchDue(before: now)
    #expect(due.count == 1)
    #expect(due[0].sourceValue == "так")
}

@Test func softDeleteSetsDeletedAt() throws {
    let db = try DatabaseManager.inMemory()
    let repo = CardRepository(database: db)

    var card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)
    #expect(card.deletedAt == nil)

    try repo.softDelete(&card)
    #expect(card.deletedAt != nil)

    let all = try repo.fetchAll()
    #expect(all.isEmpty)
}

@Test func updatePersistsChanges() throws {
    let db = try DatabaseManager.inMemory()
    let repo = CardRepository(database: db)

    var card = Card(language: "Ukrainian", sourceField: "Ukrainian", targetField: "English", sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)

    card.targetValue = "hi"
    try repo.update(&card)

    let fetched = try repo.fetchById(card.id!)
    #expect(fetched?.targetValue == "hi")
}
