import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _answerController = TextEditingController();
  core.ClozeResult? _currentCloze;
  bool _submitted = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _submitted = false;
      _answerController.clear();
    });

    final knownVocab = core.KnownVocabulary(database);
    final known = await knownVocab.getKnownWords();

    if (known.length < 3) {
      setState(() {
        _loading = false;
        _error =
            'Need at least 3 known words. Study more cards first!';
      });
      return;
    }

    final words = known.toList()..shuffle();
    final target = words.first;
    final others = words.skip(1).take(4).toList();
    final sentenceWords = [...others, target]..shuffle();
    final sentence = sentenceWords.join(' ');
    final targetIndex = sentenceWords.indexOf(target);

    setState(() {
      _currentCloze = core.ClozeResult(
        sentence: sentence,
        targetWord: target,
        targetWordIndex: targetIndex,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sentence Builder')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_currentCloze == null && !_loading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Tap Generate to create a cloze sentence'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _generate,
                        child: const Text('Generate'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_currentCloze != null && !_loading) ...[
              Expanded(
                child: Center(
                  child: Text(
                    _currentCloze!.clozeSentence,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Your answer',
                  hintText: 'Fill in the blank',
                ),
                enabled: !_submitted,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (!_submitted)
                FilledButton(
                  onPressed: () {
                    setState(() => _submitted = true);
                  },
                  child: const Text('Submit'),
                ),
              if (_submitted) ...[
                Text(
                  _answerController.text.toLowerCase() ==
                          _currentCloze!.targetWord.toLowerCase()
                      ? 'Correct!'
                      : 'Answer: ${_currentCloze!.targetWord}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _answerController.text.toLowerCase() ==
                                _currentCloze!.targetWord.toLowerCase()
                            ? Colors.green
                            : Colors.red,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Full sentence: ${_currentCloze!.sentence}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _generate,
                  child: const Text('Next Sentence'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
