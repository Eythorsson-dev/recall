import Testing
import Foundation
@testable import Core

@Suite
struct PendingGenerationBatchTests {
    private let kavu = NewWord(source: "каву", target: "coffee")
    private let vranci = NewWord(source: "вранці", target: "in the morning")

    @Test func activeNewWordsIsUnionAcrossAllSentences() {
        let batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "I love coffee.", target: "Я люблю каву.", newWords: [kavu]),
            GeneratedSentence(source: "I love coffee in the morning.",
                              target: "Я люблю каву вранці.",
                              newWords: [kavu, vranci]),
        ])
        #expect(Set(batch.activeNewWords) == [kavu, vranci])
    }

    @Test func removingOnlyReferencingSentenceDropsTheNewWord() {
        var batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "I love coffee.", target: "Я люблю каву.", newWords: [kavu]),
            GeneratedSentence(source: "Hello.", target: "Привіт.", newWords: []),
        ])
        batch.remove(at: 0)
        #expect(batch.activeNewWords.isEmpty)
        #expect(batch.sentences.count == 1)
    }

    @Test func removingOneOfTwoReferencingSentencesKeepsTheNewWord() {
        var batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "I love coffee.", target: "Я люблю каву.", newWords: [kavu]),
            GeneratedSentence(source: "Coffee is good.", target: "Кава добра.", newWords: [kavu]),
        ])
        batch.remove(at: 0)
        #expect(batch.activeNewWords == [kavu])
    }

    @Test func removingByOffsetsRecomputesNewWords() {
        var batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "A", target: "A", newWords: [kavu]),
            GeneratedSentence(source: "B", target: "B", newWords: [vranci]),
            GeneratedSentence(source: "C", target: "C", newWords: [kavu, vranci]),
        ])
        batch.remove(atOffsets: IndexSet([0, 2])) // leaves index 1 ("B" / vranci)
        #expect(batch.sentences.map(\.source) == ["B"])
        #expect(batch.activeNewWords == [vranci])
    }

    @Test func materializeCardsBundlesSentencesAndNewWordsAndRoundTripsThroughRepository() throws {
        let db = try DatabaseManager.inMemory()
        var deck = Deck(name: "Test", sourceLanguage: .english, targetLanguage: .ukrainian)
        try DeckRepository(database: db).insert(&deck)

        let batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(
                source: "I love coffee.",
                target: "Я люблю каву.",
                newWords: [kavu]
            ),
            GeneratedSentence(
                source: "Good morning.",
                target: "Доброго ранку.",
                newWords: [NewWord(source: "ранку", target: "morning")]
            ),
        ])

        var cards = batch.materializeCards(deckId: deck.id!)
        try CardRepository(database: db).insertAll(&cards)

        let progressRepo = CardProgressRepository(database: db)
        let cardRepo = CardRepository(database: db)

        let sentences = try cardRepo.fetchAll(deckId: deck.id!, kind: .sentence)
        let words = try cardRepo.fetchAll(deckId: deck.id!, kind: .word)
        #expect(sentences.count == 2)
        #expect(words.count == 2)
        // Sentence cards keep source = English, target = Ukrainian.
        #expect(sentences.contains { $0.sourceValue == "I love coffee." && $0.targetValue == "Я люблю каву." })
        // Word cards have the deck-language flip: sourceValue = English (from NewWord.target),
        // targetValue = Ukrainian (from NewWord.source).
        #expect(words.contains { $0.sourceValue == "coffee" && $0.targetValue == "каву" })
        #expect(words.contains { $0.sourceValue == "morning" && $0.targetValue == "ранку" })

        // Each new-word card gets both standard CardProgress directions.
        for word in words {
            let progress = try progressRepo.fetchAll(forCard: word.id!)
            #expect(progress.count == 2)
            #expect(Set(progress.map(\.direction)) == [.sourceToTarget, .targetToSource])
        }
    }

    @Test func materializeCardsOmitsNewWordsForRemovedSentences() throws {
        // Round-trip check that swipe-delete coordination flows through to the
        // materialized card list: removing the sole referencing sentence drops
        // the new-word card from the persisted bundle.
        let db = try DatabaseManager.inMemory()
        var deck = Deck(name: "Test", sourceLanguage: .english, targetLanguage: .ukrainian)
        try DeckRepository(database: db).insert(&deck)

        var batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "I love coffee.", target: "Я люблю каву.", newWords: [kavu]),
            GeneratedSentence(source: "Hello.", target: "Привіт.", newWords: []),
        ])
        batch.remove(at: 0)

        var cards = batch.materializeCards(deckId: deck.id!)
        try CardRepository(database: db).insertAll(&cards)

        let cardRepo = CardRepository(database: db)
        let words = try cardRepo.fetchAll(deckId: deck.id!, kind: .word)
        #expect(words.isEmpty, "no word-cards should land — the only sentence referencing 'каву' was removed")
        let sentences = try cardRepo.fetchAll(deckId: deck.id!, kind: .sentence)
        #expect(sentences.count == 1)
    }

    @Test func activeNewWordsPreservesEncounterOrder() {
        let batch = PendingGenerationBatch(sentences: [
            GeneratedSentence(source: "A", target: "A", newWords: [vranci, kavu]),
            GeneratedSentence(source: "B", target: "B", newWords: [kavu]),
        ])
        #expect(batch.activeNewWords == [vranci, kavu])
    }
}
