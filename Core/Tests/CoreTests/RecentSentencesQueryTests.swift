import Testing
import Foundation
@testable import Core

private func makeDeck(in db: DatabaseManager, name: String = "Test") throws -> Deck {
    var deck = Deck(name: name, sourceLanguage: .english, targetLanguage: .ukrainian)
    try DeckRepository(database: db).insert(&deck)
    return deck
}

private func insertCard(
    deckId: Int64,
    source: String,
    target: String,
    kind: CardKind,
    createdAt: Date,
    deletedAt: Date? = nil,
    in db: DatabaseManager
) throws -> Card {
    let repo = CardRepository(database: db)
    var card = Card(
        deckId: deckId,
        sourceValue: source,
        targetValue: target,
        kind: kind,
        createdAt: createdAt,
        updatedAt: createdAt,
        deletedAt: deletedAt
    )
    try repo.insert(&card)
    return card
}

@Suite(.serialized)
struct RecentSentencesQueryTests {
    @Test func returnsTargetValuesOrderedByCreatedAtDesc() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let base = Date(timeIntervalSince1970: 1_000_000_000)

        _ = try insertCard(
            deckId: deck.id!,
            source: "oldest",
            target: "найстаріше",
            kind: .sentence,
            createdAt: base,
            in: db
        )
        _ = try insertCard(
            deckId: deck.id!,
            source: "middle",
            target: "середнє",
            kind: .sentence,
            createdAt: base.addingTimeInterval(60),
            in: db
        )
        _ = try insertCard(
            deckId: deck.id!,
            source: "newest",
            target: "найновіше",
            kind: .sentence,
            createdAt: base.addingTimeInterval(120),
            in: db
        )

        let strings = try RecentSentencesQuery(database: db).fetch(deckId: deck.id!)
        #expect(strings == ["найновіше", "середнє", "найстаріше"])
    }

    @Test func limitsTo30ByDefault() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let base = Date(timeIntervalSince1970: 1_000_000_000)

        for i in 0..<35 {
            _ = try insertCard(
                deckId: deck.id!,
                source: "src-\(i)",
                target: "tgt-\(i)",
                kind: .sentence,
                createdAt: base.addingTimeInterval(TimeInterval(i)),
                in: db
            )
        }

        let strings = try RecentSentencesQuery(database: db).fetch(deckId: deck.id!)
        #expect(strings.count == 30)
        // Most recent first; "tgt-34" is the newest
        #expect(strings.first == "tgt-34")
        #expect(strings.last == "tgt-5")
    }

    @Test func excludesWordKind() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let base = Date(timeIntervalSince1970: 1_000_000_000)

        _ = try insertCard(
            deckId: deck.id!,
            source: "coffee",
            target: "кава",
            kind: .word,
            createdAt: base.addingTimeInterval(100),
            in: db
        )
        _ = try insertCard(
            deckId: deck.id!,
            source: "I love coffee.",
            target: "Я люблю каву.",
            kind: .sentence,
            createdAt: base.addingTimeInterval(50),
            in: db
        )

        let strings = try RecentSentencesQuery(database: db).fetch(deckId: deck.id!)
        #expect(strings == ["Я люблю каву."])
    }

    @Test func excludesSoftDeletedSentences() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)
        let base = Date(timeIntervalSince1970: 1_000_000_000)

        _ = try insertCard(
            deckId: deck.id!,
            source: "Good morning.",
            target: "Доброго ранку.",
            kind: .sentence,
            createdAt: base,
            deletedAt: Date(),
            in: db
        )
        _ = try insertCard(
            deckId: deck.id!,
            source: "Thanks.",
            target: "Дякую.",
            kind: .sentence,
            createdAt: base.addingTimeInterval(10),
            in: db
        )

        let strings = try RecentSentencesQuery(database: db).fetch(deckId: deck.id!)
        #expect(strings == ["Дякую."])
    }

    @Test func scopesToSpecifiedDeck() throws {
        let db = try DatabaseManager.inMemory()
        let deckA = try makeDeck(in: db, name: "A")
        let deckB = try makeDeck(in: db, name: "B")
        let base = Date(timeIntervalSince1970: 1_000_000_000)

        _ = try insertCard(
            deckId: deckA.id!,
            source: "A sentence",
            target: "Речення А",
            kind: .sentence,
            createdAt: base,
            in: db
        )
        _ = try insertCard(
            deckId: deckB.id!,
            source: "B sentence",
            target: "Речення Б",
            kind: .sentence,
            createdAt: base,
            in: db
        )

        let stringsA = try RecentSentencesQuery(database: db).fetch(deckId: deckA.id!)
        #expect(stringsA == ["Речення А"])

        let stringsB = try RecentSentencesQuery(database: db).fetch(deckId: deckB.id!)
        #expect(stringsB == ["Речення Б"])
    }

    @Test func returnsEmptyWhenNoSentenceCards() throws {
        let db = try DatabaseManager.inMemory()
        let deck = try makeDeck(in: db)

        let strings = try RecentSentencesQuery(database: db).fetch(deckId: deck.id!)
        #expect(strings.isEmpty)
    }
}
