import Testing
import Foundation
@testable import Core

private func makeTestDeck(in db: DatabaseManager) throws -> Deck {
    let repo = DeckRepository(database: db)
    var deck = Deck(name: "Test", sourceLanguage: .ukrainian, targetLanguage: .english)
    try repo.insert(&deck)
    return deck
}

private func makeTestCard(in db: DatabaseManager, deck: Deck) throws -> Card {
    let repo = CardRepository(database: db)
    var card = Card(deckId: deck.id!, sourceValue: "привіт", targetValue: "hello")
    try repo.insert(&card)
    return card
}

@Test func tagInsertAndFetchAll() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var tag = Tag(name: "Greetings")
    try repo.insert(&tag)

    #expect(tag.id != nil)
    let all = try repo.fetchAll()
    #expect(all.count == 1)
    #expect(all[0].name == "Greetings")
}

@Test func tagFetchAllOrderedAlphabetically() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var tagB = Tag(name: "Zoo")
    var tagA = Tag(name: "Animals")
    try repo.insert(&tagB)
    try repo.insert(&tagA)

    let all = try repo.fetchAll()
    #expect(all.count == 2)
    #expect(all[0].name == "Animals")
    #expect(all[1].name == "Zoo")
}

@Test func tagUpdate() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var tag = Tag(name: "Greetings")
    try repo.insert(&tag)

    tag.name = "Farewells"
    try repo.update(&tag)

    let all = try repo.fetchAll()
    #expect(all.count == 1)
    #expect(all[0].name == "Farewells")
}

@Test func tagDelete() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var tag = Tag(name: "Greetings")
    try repo.insert(&tag)
    #expect(try repo.fetchAll().count == 1)

    try repo.delete(tag)
    #expect(try repo.fetchAll().isEmpty)
}

@Test func tagDeleteCascadesToCardTag() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)
    let deck = try makeTestDeck(in: db)
    let card = try makeTestCard(in: db, deck: deck)

    var tag = Tag(name: "Greetings")
    try repo.insert(&tag)
    try repo.setTags([tag.id!], forCard: card.id!)

    let before = try repo.fetchTags(forCard: card.id!)
    #expect(before.count == 1)

    try repo.delete(tag)

    let after = try repo.fetchTags(forCard: card.id!)
    #expect(after.isEmpty)
}

@Test func setTagsForCard() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)
    let deck = try makeTestDeck(in: db)
    let card = try makeTestCard(in: db, deck: deck)

    var tag1 = Tag(name: "A")
    var tag2 = Tag(name: "B")
    try repo.insert(&tag1)
    try repo.insert(&tag2)

    try repo.setTags([tag1.id!, tag2.id!], forCard: card.id!)
    let tags = try repo.fetchTags(forCard: card.id!)
    #expect(tags.count == 2)
}

@Test func setTagsReplacesExisting() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)
    let deck = try makeTestDeck(in: db)
    let card = try makeTestCard(in: db, deck: deck)

    var tag1 = Tag(name: "A")
    var tag2 = Tag(name: "B")
    try repo.insert(&tag1)
    try repo.insert(&tag2)

    try repo.setTags([tag1.id!, tag2.id!], forCard: card.id!)
    try repo.setTags([tag2.id!], forCard: card.id!)

    let tags = try repo.fetchTags(forCard: card.id!)
    #expect(tags.count == 1)
    #expect(tags[0].name == "B")
}

@Test func setTagsWithEmptyArrayClearsAll() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)
    let deck = try makeTestDeck(in: db)
    let card = try makeTestCard(in: db, deck: deck)

    var tag = Tag(name: "A")
    try repo.insert(&tag)
    try repo.setTags([tag.id!], forCard: card.id!)
    try repo.setTags([], forCard: card.id!)

    let tags = try repo.fetchTags(forCard: card.id!)
    #expect(tags.isEmpty)
}

@Test func searchTagsMatchesSubstring() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var t1 = Tag(name: "Greetings")
    var t2 = Tag(name: "Farewells")
    var t3 = Tag(name: "Great words")
    try repo.insert(&t1)
    try repo.insert(&t2)
    try repo.insert(&t3)

    let results = try repo.searchTags(matching: "gre")
    #expect(results.count == 2)
    #expect(results.map(\.name).contains("Greetings"))
    #expect(results.map(\.name).contains("Great words"))
}

@Test func searchTagsIsCaseInsensitive() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var tag = Tag(name: "Greetings")
    try repo.insert(&tag)

    let results = try repo.searchTags(matching: "GREET")
    #expect(results.count == 1)
}

@Test func searchTagsEmptyQueryReturnsAll() throws {
    let db = try DatabaseManager.inMemory()
    let repo = TagRepository(database: db)

    var t1 = Tag(name: "A")
    var t2 = Tag(name: "B")
    try repo.insert(&t1)
    try repo.insert(&t2)

    let results = try repo.searchTags(matching: "")
    #expect(results.count == 2)
}

@Test func fetchDueCountWithTagFilter() throws {
    let db = try DatabaseManager.inMemory()
    let deck = try makeTestDeck(in: db)
    let cardRepo = CardRepository(database: db)
    let tagRepo = TagRepository(database: db)
    let progressRepo = CardProgressRepository(database: db)

    var card1 = Card(deckId: deck.id!, sourceValue: "one", targetValue: "one_t")
    var card2 = Card(deckId: deck.id!, sourceValue: "two", targetValue: "two_t")
    try cardRepo.insert(&card1)
    try cardRepo.insert(&card2)

    var tag = Tag(name: "Tagged")
    try tagRepo.insert(&tag)
    try tagRepo.setTags([tag.id!], forCard: card1.id!)

    // Without tag filter, both cards count
    let totalCount = try progressRepo.fetchCardCount(deckIds: [deck.id!])
    #expect(totalCount == 2)

    // With tag filter, only card1
    let taggedCount = try progressRepo.fetchCardCount(deckIds: [deck.id!], tagIds: [tag.id!])
    #expect(taggedCount == 1)
}

@Test func selectedTagIdsPersistAndRestore() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    let initial = try repo.selectedTagIds()
    #expect(initial.isEmpty)

    try repo.setSelectedTagIds([1, 2, 3])
    let fetched = try repo.selectedTagIds()
    #expect(fetched == [1, 2, 3])
}

@Test func selectedTagIdsEmptyArrayClearsStorage() throws {
    let db = try DatabaseManager.inMemory()
    let repo = SettingsRepository(database: db)

    try repo.setSelectedTagIds([1, 2])
    try repo.setSelectedTagIds([])
    let fetched = try repo.selectedTagIds()
    #expect(fetched.isEmpty)
}
