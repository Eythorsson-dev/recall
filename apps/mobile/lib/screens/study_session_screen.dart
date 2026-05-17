import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;
import 'package:fsrs/fsrs.dart' as fsrs;

import '../main.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';

class StudySessionScreen extends StatefulWidget {
  final StudySessionConfig config;
  final Set<int>? filterCardIds;

  const StudySessionScreen({
    super.key,
    required this.config,
    this.filterCardIds,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final _scheduler = fsrs.Scheduler(enableFuzzing: true);
  final _tts = TtsService();
  List<core.CardWithFsrs> _queue = [];
  int _currentIndex = 0;
  bool _revealed = false;
  bool _loading = true;
  DateTime? _cardShownAt;

  bool get _isListeningMode =>
      widget.config.studyMode != StudyMode.reading;
  bool get _hideText =>
      widget.config.studyMode == StudyMode.listeningWithoutText;

  @override
  void initState() {
    super.initState();
    _tts.init();
    _loadCards();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    var cards = await cardRepository.getCardsDueToday();
    if (widget.filterCardIds != null) {
      cards = cards
          .where((c) => widget.filterCardIds!.contains(c.card.id))
          .toList();
    }
    setState(() {
      _queue = cards;
      _loading = false;
      _cardShownAt = DateTime.now();
    });
    if (cards.isNotEmpty && _isListeningMode) {
      _autoPlayTts();
    }
  }

  Future<void> _autoPlayTts() async {
    if (_currentIndex >= _queue.length) return;
    final current = _queue[_currentIndex];
    final (prompt, _) = _getPromptAndAnswer(current.card);
    final speakable = _getSpeakableFields(current.card);
    final fields = _getFields(current.card);
    final keys = fields.keys.toList();

    final promptKey = widget.config.direction == 'target_to_source'
        ? (keys.length > 1 ? keys[1] : keys[0])
        : keys[0];

    if (speakable[promptKey] == true) {
      await _tts.speak(prompt);
    }
  }

  Map<String, String> _getFields(core.Card card) {
    return Map<String, String>.from(
        jsonDecode(card.fields) as Map<String, dynamic>);
  }

  Map<String, bool> _getSpeakableFields(core.Card card) {
    return Map<String, bool>.from(
        jsonDecode(card.fieldSpeakable) as Map<String, dynamic>);
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

  Widget _speakerIcon(core.Card card, String fieldKey) {
    final speakable = _getSpeakableFields(card);
    if (speakable[fieldKey] != true) return const SizedBox.shrink();

    final fields = _getFields(card);
    return IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () => _tts.speak(fields[fieldKey]!),
    );
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
    final fields = _getFields(current.card);
    final keys = fields.keys.toList();
    final promptKey = widget.config.direction == 'target_to_source'
        ? (keys.length > 1 ? keys[1] : keys[0])
        : keys[0];
    final answerKey = widget.config.direction == 'target_to_source'
        ? keys[0]
        : (keys.length > 1 ? keys[1] : keys[0]);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} of ${_queue.length}'),
        actions: [
          if (_isListeningMode)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Replay',
              onPressed: () {
                _tts.replay(prompt);
              },
            ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            tooltip: 'Playback Speed',
            onSelected: (speed) {
              _tts.setSpeed(speed);
              setState(() {});
            },
            itemBuilder: (_) => [
              for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                PopupMenuItem(
                  value: speed,
                  child: Text(
                    '${speed}x${speed == _tts.playbackSpeed ? ' ✓' : ''}',
                  ),
                ),
            ],
          ),
        ],
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_hideText || _revealed)
                        Text(
                          prompt,
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      if (_hideText && !_revealed)
                        const Icon(Icons.hearing, size: 64),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _speakerIcon(current.card, promptKey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_revealed) ...[
                const Divider(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          answer,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _speakerIcon(current.card, answerKey),
                          ],
                        ),
                      ],
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
      studyMode: widget.config.studyModeString,
      direction: widget.config.direction,
      timeToRevealSeconds: timeToReveal,
      audioReplayCount: _tts.replayCount,
      playbackSpeed: _tts.playbackSpeed,
    );

    await _tts.stop();
    _tts.resetReplayCount();

    setState(() {
      _currentIndex++;
      _revealed = false;
      _cardShownAt = DateTime.now();
    });

    if (_currentIndex < _queue.length && _isListeningMode) {
      _autoPlayTts();
    }
  }
}
