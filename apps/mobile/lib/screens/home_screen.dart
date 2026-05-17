import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';
import 'sentence_builder_screen.dart';
import 'study_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dueCount = 0;
  core.ProgressStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final due = await cardRepository.getCardsDueToday();
    final stats = await progressTracker.getStats();
    if (mounted) {
      setState(() {
        _dueCount = due.length;
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recall')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_stats != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statCard(
                    context,
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '${_stats!.streak}',
                    color: Colors.orange,
                  ),
                  _statCard(
                    context,
                    icon: Icons.school,
                    label: 'Learned',
                    value: '${_stats!.wordsLearned}',
                    color: Colors.green,
                  ),
                  _statCard(
                    context,
                    icon: Icons.check_circle,
                    label: 'Today',
                    value: '${_stats!.sessionProgress} / ${_stats!.sessionTotal}',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            Text(
              '$_dueCount cards due today',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _dueCount > 0 ? () => _startStudySession() : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Study Session'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SentenceBuilderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Sentence Builder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _startStudySession() async {
    final result = await showDialog<StudySessionConfig>(
      context: context,
      builder: (context) => const StudySessionConfigDialog(),
    );
    if (result != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudySessionScreen(config: result),
        ),
      );
      _loadData();
    }
  }
}

enum StudyMode { reading, listeningWithText, listeningWithoutText }

class StudySessionConfig {
  final String direction;
  final StudyMode studyMode;

  const StudySessionConfig({
    required this.direction,
    this.studyMode = StudyMode.reading,
  });

  String get studyModeString {
    switch (studyMode) {
      case StudyMode.reading:
        return 'reading';
      case StudyMode.listeningWithText:
        return 'listening_with_text';
      case StudyMode.listeningWithoutText:
        return 'listening_without_text';
    }
  }
}

class StudySessionConfigDialog extends StatefulWidget {
  const StudySessionConfigDialog({super.key});

  @override
  State<StudySessionConfigDialog> createState() =>
      _StudySessionConfigDialogState();
}

class _StudySessionConfigDialogState extends State<StudySessionConfigDialog> {
  String _direction = 'source_to_target';
  StudyMode _studyMode = StudyMode.reading;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Study Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direction',
                style: Theme.of(context).textTheme.titleSmall),
            RadioGroup<String>(
              groupValue: _direction,
              onChanged: (v) =>
                  setState(() => _direction = v ?? _direction),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Source → Target'),
                    value: 'source_to_target',
                  ),
                  RadioListTile<String>(
                    title: const Text('Target → Source'),
                    value: 'target_to_source',
                  ),
                  RadioListTile<String>(
                    title: const Text('Both'),
                    value: 'both',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Study Mode',
                style: Theme.of(context).textTheme.titleSmall),
            RadioGroup<StudyMode>(
              groupValue: _studyMode,
              onChanged: (v) =>
                  setState(() => _studyMode = v ?? _studyMode),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<StudyMode>(
                    title: const Text('Reading'),
                    subtitle: const Text('Manual TTS tap only'),
                    value: StudyMode.reading,
                  ),
                  RadioListTile<StudyMode>(
                    title: const Text('Listening with Text'),
                    subtitle: const Text('TTS auto-plays, text visible'),
                    value: StudyMode.listeningWithText,
                  ),
                  RadioListTile<StudyMode>(
                    title: const Text('Listening without Text'),
                    subtitle: const Text('TTS auto-plays, text hidden'),
                    value: StudyMode.listeningWithoutText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            StudySessionConfig(
              direction: _direction,
              studyMode: _studyMode,
            ),
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}
