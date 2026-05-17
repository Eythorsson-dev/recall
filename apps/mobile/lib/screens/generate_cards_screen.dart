import 'package:flutter/material.dart';

import '../main.dart';
import 'generation_review_screen.dart';

class GenerateCardsScreen extends StatefulWidget {
  const GenerateCardsScreen({super.key});

  @override
  State<GenerateCardsScreen> createState() => _GenerateCardsScreenState();
}

class _GenerateCardsScreenState extends State<GenerateCardsScreen> {
  final _promptController = TextEditingController();
  final _sourceLanguageController = TextEditingController(text: 'Ukrainian');
  final _targetLanguageController = TextEditingController(text: 'English');
  bool _generating = false;

  @override
  void dispose() {
    _promptController.dispose();
    _sourceLanguageController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Cards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _sourceLanguageController,
              decoration: const InputDecoration(
                labelText: 'Source Language',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetLanguageController,
              decoration: const InputDecoration(
                labelText: 'Target Language',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'e.g. 50 most common Ukrainian words',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _generating ? null : _generate,
              child: _generating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    if (_promptController.text.isEmpty) return;

    setState(() => _generating = true);

    try {
      final cards = await cardGenerationService.generate(
        prompt: _promptController.text,
        sourceLanguage: _sourceLanguageController.text,
        targetLanguage: _targetLanguageController.text,
      );

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GenerationReviewScreen(
              generatedCards: cards,
              language: _sourceLanguageController.text,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
