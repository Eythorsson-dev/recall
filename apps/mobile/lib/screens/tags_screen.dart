import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<String> _tags = [];
  List<core.Card> _untaggedCards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tags = await savedFilterEngine.getAllTags();
    final untagged = await savedFilterEngine.getUntaggedCards();
    if (mounted) {
      setState(() {
        _tags = tags;
        _untaggedCards = untagged;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: ListView(
        children: [
          if (_untaggedCards.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.label_off),
              title: const Text('Untagged Cards'),
              trailing: Text('${_untaggedCards.length}'),
              onTap: () => _showUntaggedCards(),
            ),
          if (_untaggedCards.isNotEmpty) const Divider(),
          ..._tags.map((tag) => ListTile(
                leading: const Icon(Icons.label),
                title: Text(tag),
              )),
          if (_tags.isEmpty && _untaggedCards.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No tags yet. Add tags when creating cards.'),
              ),
            ),
        ],
      ),
    );
  }

  void _showUntaggedCards() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Untagged Cards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._untaggedCards.map((card) {
            final fields = Map<String, String>.from(
                jsonDecode(card.fields) as Map<String, dynamic>);
            return ListTile(
              title: Text(fields.values.first),
              subtitle: Text(card.language),
            );
          }),
        ],
      ),
    );
  }
}
