class GeneratedCard {
  final String sourceFieldName;
  final String sourceValue;
  final String targetFieldName;
  final String targetValue;
  bool accepted;

  GeneratedCard({
    required this.sourceFieldName,
    required this.sourceValue,
    required this.targetFieldName,
    required this.targetValue,
    this.accepted = false,
  });
}

abstract class CardGenerationService {
  Future<List<GeneratedCard>> generate({
    required String prompt,
    required String sourceLanguage,
    required String targetLanguage,
  });
}

class StubCardGenerationService implements CardGenerationService {
  @override
  Future<List<GeneratedCard>> generate({
    required String prompt,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      GeneratedCard(
        sourceFieldName: sourceLanguage,
        sourceValue: 'привіт',
        targetFieldName: targetLanguage,
        targetValue: 'hello',
      ),
      GeneratedCard(
        sourceFieldName: sourceLanguage,
        sourceValue: 'дякую',
        targetFieldName: targetLanguage,
        targetValue: 'thank you',
      ),
      GeneratedCard(
        sourceFieldName: sourceLanguage,
        sourceValue: 'так',
        targetFieldName: targetLanguage,
        targetValue: 'yes',
      ),
    ];
  }
}
