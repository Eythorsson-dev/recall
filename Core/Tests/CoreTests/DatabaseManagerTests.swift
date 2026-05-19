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

@Test func cardInsertAndFetch() async throws {
    let db = try DatabaseManager.inMemory()
    var card = Card(
        language: "Ukrainian",
        sourceField: "Ukrainian",
        targetField: "English",
        sourceValue: "привіт",
        targetValue: "hello"
    )
    try db.writer.write { dbConn in
        try card.insert(dbConn)
    }
    let fetched = try db.reader.read { dbConn in
        try Card.fetchAll(dbConn)
    }
    #expect(fetched.count == 1)
    #expect(fetched[0].sourceValue == "привіт")
    #expect(fetched[0].targetValue == "hello")
    #expect(fetched[0].language == "Ukrainian")
}
