import 'package:flutter/material.dart';

import '../main.dart';
import 'study_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dueCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDueCount();
  }

  Future<void> _loadDueCount() async {
    final due = await cardRepository.getCardsDueToday();
    if (mounted) {
      setState(() => _dueCount = due.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recall')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      ),
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
      _loadDueCount();
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
