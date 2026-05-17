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

class StudySessionConfig {
  final String direction;

  const StudySessionConfig({required this.direction});
}

class StudySessionConfigDialog extends StatefulWidget {
  const StudySessionConfigDialog({super.key});

  @override
  State<StudySessionConfigDialog> createState() =>
      _StudySessionConfigDialogState();
}

class _StudySessionConfigDialogState extends State<StudySessionConfigDialog> {
  String _direction = 'source_to_target';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Study Direction'),
      content: RadioGroup<String>(
        groupValue: _direction,
        onChanged: (v) => setState(() => _direction = v ?? _direction),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(StudySessionConfig(direction: _direction)),
          child: const Text('Start'),
        ),
      ],
    );
  }
}
