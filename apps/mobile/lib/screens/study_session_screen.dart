import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;
import 'package:fsrs/fsrs.dart' as fsrs;

import '../main.dart';
import 'home_screen.dart';

class StudySessionScreen extends StatefulWidget {
  final StudySessionConfig config;

  const StudySessionScreen({super.key, required this.config});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final _scheduler = fsrs.Scheduler(enableFuzzing: true);
  List<core.CardWithFsrs> _queue = [];
  int _currentIndex = 0;
  bool _revealed = false;
  bool _loading = true;
  DateTime? _cardShownAt;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await cardRepository.getCardsDueToday();
    setState(() {
      _queue = cards;
      _loading = false;
      _cardShownAt = DateTime.now();
    });
  }

  Map<String, String> _getFields(core.Card card) {
    return Map<String, String>.from(
        jsonDecode(card.fields) as Map<String, dynamic>);
  }

  (String prompt, String answer) _getPromptAndAnswer(core.Card card) {
    final fields = _getFields(card);
    final keys = fields.keys.toList();
    if (keys.length < 2) {
      return (fields.values.first, '');
    }

    switch (widget.config.direction) {
      case 'target_to_source':
        return (fields[keys[1]]!, fields[keys[0]]!);
      case 'source_to_target':
      default:
        return (fields[keys[0]]!, fields[keys[1]]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentIndex >= _queue.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Complete')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Done for today!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final current = _queue[_currentIndex];
    final (prompt, answer) = _getPromptAndAnswer(current.card);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_currentIndex + 1} of ${_queue.length}'),
      ),
      body: GestureDetector(
        onTap: () {
          if (!_revealed) {
            setState(() => _revealed = true);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    prompt,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (_revealed) ...[
                const Divider(),
                Expanded(
                  child: Center(
                    child: Text(
                      answer,
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ratingButton('Again', fsrs.Rating.again, Colors.red),
                    _ratingButton('Hard', fsrs.Rating.hard, Colors.orange),
                    _ratingButton('Good', fsrs.Rating.good, Colors.green),
                    _ratingButton('Easy', fsrs.Rating.easy, Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Tap to reveal',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingButton(String label, fsrs.Rating rating, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => _rate(rating),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Future<void> _rate(fsrs.Rating rating) async {
    final current = _queue[_currentIndex];
    final timeToReveal = _cardShownAt != null
        ? DateTime.now().difference(_cardShownAt!).inMilliseconds / 1000.0
        : 0.0;

    final state = current.fsrsState;
    final fsrsCard = fsrs.Card(
      cardId: current.card.id,
      state: fsrs.State.fromValue(state.state),
      step: state.step,
      stability: state.stability,
      difficulty: state.difficulty,
      due: state.due,
      lastReview: state.lastReview,
    );

    final result = _scheduler.reviewCard(fsrsCard, rating);
    await cardRepository.updateFsrsState(current.card.id, result.card);

    await cardRepository.recordReviewEvent(
      cardId: current.card.id,
      rating: rating.value,
      studyMode: 'reading',
      direction: widget.config.direction,
      timeToRevealSeconds: timeToReveal,
    );

    setState(() {
      _currentIndex++;
      _revealed = false;
      _cardShownAt = DateTime.now();
    });
  }
}
