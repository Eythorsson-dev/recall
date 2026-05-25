import Foundation

/// Splits a sentence into normalized word tokens for the defensive new-word
/// extraction pass in `SentenceGenerator`.
///
/// A token is a maximal run of letters, digits, or apostrophes. Everything
/// else (whitespace, punctuation, em-dashes, etc.) is a separator. Tokens are
/// lowercased so that capitalized sentence-starts compare cleanly against the
/// known-vocabulary list. Works for Cyrillic and any other script in Unicode's
/// letter category — there is nothing Ukrainian-specific in the rules.
public enum SentenceTokenizer {
    public static func tokens(in sentence: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for scalar in sentence.unicodeScalars {
            if isWordScalar(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current.lowercased())
                current = ""
            }
        }
        if !current.isEmpty {
            tokens.append(current.lowercased())
        }
        return tokens
    }

    private static func isWordScalar(_ scalar: Unicode.Scalar) -> Bool {
        if CharacterSet.letters.contains(scalar) { return true }
        if CharacterSet.decimalDigits.contains(scalar) { return true }
        // Apostrophes (straight + curly) belong inside words (e.g. Ukrainian п'ять).
        if scalar == "'" || scalar == "\u{2019}" { return true }
        return false
    }
}
