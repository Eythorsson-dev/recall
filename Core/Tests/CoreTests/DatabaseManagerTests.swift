import Testing
import Foundation
@testable import Core

@Test func databaseOpensAndMigrates() async throws {
    let db = try DatabaseManager.inMemory()
    let count = try db.reader.read { db in
        try Card.fetchCount(db)
    }
    #expect(count == 0)
}

@Test func deckInsertAndFetch() async throws {
    let db = try DatabaseManager.inMemory()
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Ukrainian → English", sourceLanguage: .ukrainian, targetLanguage: .english)
    try db.writer.write { dbConn in try deck.insert(dbConn) }

    let fetched = try repo.fetchAll()
    #expect(fetched.count == 1)
    #expect(fetched[0].sourceLanguage == .ukrainian)
    #expect(fetched[0].targetLanguage == .english)
}

@Test func cardInsertAndFetch() async throws {
    let db = try DatabaseManager.inMemory()
    let deckRepo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try deckRepo.insert(&deck)

    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try db.writer.write { dbConn in try card.insert(dbConn) }

    let fetched = try db.reader.read { dbConn in try Card.fetchAll(dbConn) }
    #expect(fetched.count == 1)
    #expect(fetched[0].sourceValue == "привіт")
    #expect(fetched[0].targetValue == "hello")
    #expect(fetched[0].deckId == deck.id!)
}
