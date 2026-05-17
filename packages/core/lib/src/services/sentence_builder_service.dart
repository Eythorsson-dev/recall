import '../database/database.dart';

class ClozeResult {
  final String sentence;
  final String targetWord;
  final int targetWordIndex;

  const ClozeResult({
    required this.sentence,
    required this.targetWord,
    required this.targetWordIndex,
  });

  String get clozeSentence {
    final words = sentence.split(' ');
    words[targetWordIndex] = '____';
    return words.join(' ');
  }
}

class KnownVocabulary {
  final RecallDatabase _db;

  KnownVocabulary(this._db);

  Future<Set<String>> getKnownWords() async {
    final events = await _db.select(_db.reviewEvents).get();

    final goodOrEasyCardIds = <int>{};
    for (final event in events) {
      if (event.rating >= 3) {
        goodOrEasyCardIds.add(event.cardId);
      }
    }

    if (goodOrEasyCardIds.isEmpty) return {};

    final cards = await _db.select(_db.cards).get();
    final knownWords = <String>{};

    for (final card in cards) {
      if (!goodOrEasyCardIds.contains(card.id)) continue;
      if (card.deletedAt != null) continue;

      final fields = card.fields;
      final wordsInFields = _extractWords(fields);
      knownWords.addAll(wordsInFields);
    }

    return knownWords;
  }

  Set<String> _extractWords(String fieldsJson) {
    final words = <String>{};
    final regex = RegExp(r'[\p{L}\p{M}]+', unicode: true);
    for (final match in regex.allMatches(fieldsJson)) {
      words.add(match.group(0)!.toLowerCase());
    }
    return words;
  }
}

class SentenceValidator {
  static bool validate(String sentence, String targetWord, Set<String> knownWords) {
    final words = sentence
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\p{L}\p{M}]', unicode: true), ''))
        .where((w) => w.isNotEmpty)
        .map((w) => w.toLowerCase())
        .toList();

    final targetLower = targetWord.toLowerCase();

    for (final word in words) {
      if (word == targetLower) continue;
      if (!knownWords.contains(word)) return false;
    }

    return true;
  }
}
