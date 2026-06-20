import Testing
@testable import Core

@Suite
struct SentenceTokenizerTests {
    @Test func normalizesCaseAndStripsPunctuation() {
        let tokens = SentenceTokenizer.tokens(in: "Доброго ранку, друже!")
        #expect(tokens == ["доброго", "ранку", "друже"])
    }

    @Test func handlesQuestionMarkAndEmDash() {
        let tokens = SentenceTokenizer.tokens(in: "Як справи — добре?")
        #expect(tokens == ["як", "справи", "добре"])
    }

    @Test func handlesCapitalizedSentenceStart() {
        let tokens = SentenceTokenizer.tokens(in: "Я люблю каву вранці.")
        #expect(tokens == ["я", "люблю", "каву", "вранці"])
    }

    @Test func dropsEmptyAndWhitespaceOnlyTokens() {
        let tokens = SentenceTokenizer.tokens(in: "  Доброго  ранку!  ")
        #expect(tokens == ["доброго", "ранку"])
    }

    @Test func handlesMixedCyrillicAndLatin() {
        // Should still produce both — used in tests, not common in real data.
        let tokens = SentenceTokenizer.tokens(in: "Hello, друже!")
        #expect(tokens == ["hello", "друже"])
    }

    @Test func handlesApostrophes() {
        // Ukrainian uses apostrophe inside words (e.g. п'ять). Keep the word intact.
        let tokens = SentenceTokenizer.tokens(in: "Мені п'ять років.")
        #expect(tokens.contains("п'ять"))
        #expect(!tokens.contains("п"))
        #expect(!tokens.contains("ять"))
    }
}
