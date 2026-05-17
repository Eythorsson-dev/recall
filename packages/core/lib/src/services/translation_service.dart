abstract class TranslationService {
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  });
}

class StubTranslationService implements TranslationService {
  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '[translated] $text';
  }
}
