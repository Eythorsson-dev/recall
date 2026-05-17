import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';
import 'home_screen.dart';
import 'study_session_screen.dart';

class SavedFiltersScreen extends StatefulWidget {
  const SavedFiltersScreen({super.key});

  @override
  State<SavedFiltersScreen> createState() => _SavedFiltersScreenState();
}

class _SavedFiltersScreenState extends State<SavedFiltersScreen> {
  List<core.SavedFilter> _filters = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final filters = await savedFilterEngine.getAllFilters();
    if (mounted) setState(() => _filters = filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Filters')),
      body: _filters.isEmpty
          ? const Center(child: Text('No saved filters yet.'))
          : ListView.builder(
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final tags = (jsonDecode(filter.tagQuery) as List)
                    .cast<String>();
                return ListTile(
                  title: Text(filter.name),
                  subtitle: Text(
                    [
                      if (filter.language != null) filter.language!,
                      if (tags.isNotEmpty)
                        '${filter.logicOperator.toUpperCase()}: ${tags.join(", ")}',
                    ].join(' • '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _studyFromFilter(filter),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await savedFilterEngine.deleteFilter(filter.id);
                          _loadFilters();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFilter,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _studyFromFilter(core.SavedFilter filter) async {
    final config = await showDialog<StudySessionConfig>(
      context: context,
      builder: (context) => const StudySessionConfigDialog(),
    );
    if (config != null && mounted) {
      final cards = await savedFilterEngine.applyFilter(filter);
      if (cards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cards match this filter')),
          );
        }
        return;
      }
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudySessionScreen(
              config: config,
              filterCardIds: cards.map((c) => c.id).toSet(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _createFilter() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateFilterScreen()),
    );
    if (result == true) _loadFilters();
  }
}

class CreateFilterScreen extends StatefulWidget {
  const CreateFilterScreen({super.key});

  @override
  State<CreateFilterScreen> createState() => _CreateFilterScreenState();
}

class _CreateFilterScreenState extends State<CreateFilterScreen> {
  final _nameController = TextEditingController();
  final _languageController = TextEditingController();
  final _tagController = TextEditingController();
  final _selectedTags = <String>[];
  String _logicOperator = 'and';
  List<String> _allTags = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await savedFilterEngine.getAllTags();
    if (mounted) setState(() => _allTags = tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _languageController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Saved Filter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Filter Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _languageController,
            decoration: const InputDecoration(
              labelText: 'Language (optional)',
              hintText: 'e.g. Ukrainian',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Logic: '),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'and', label: Text('AND')),
                  ButtonSegment(value: 'or', label: Text('OR')),
                ],
                selected: {_logicOperator},
                onSelectionChanged: (v) =>
                    setState(() => _logicOperator = v.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              labelText: 'Add Tag',
              hintText: 'Type to search tags',
            ),
            onChanged: (v) {
              setState(() {
                _suggestions = savedFilterEngine.fuzzyMatchTags(_allTags, v);
              });
            },
          ),
          if (_suggestions.isNotEmpty)
            Wrap(
              spacing: 4,
              children: _suggestions
                  .where((t) => !_selectedTags.contains(t))
                  .map((tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          setState(() {
                            _selectedTags.add(tag);
                            _tagController.clear();
                            _suggestions = [];
                          });
                        },
                      ))
                  .toList(),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: _selectedTags
                .map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () =>
                          setState(() => _selectedTags.remove(tag)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Filter'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;

    await savedFilterEngine.createFilter(
      name: _nameController.text,
      language: _languageController.text.isEmpty
          ? null
          : _languageController.text,
      tags: _selectedTags,
      logicOperator: _logicOperator,
    );

    if (mounted) Navigator.of(context).pop(true);
  }
}
