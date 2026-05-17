import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';
import 'card_form_screen.dart';
import 'generate_cards_screen.dart';
import 'saved_filters_screen.dart';
import 'tags_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<core.Card> _cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await cardRepository.getAllCards();
    if (mounted) setState(() => _cards = cards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: 'Tags',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TagsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Saved Filters',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const SavedFiltersScreen()),
            ),
          ),
        ],
      ),
      body: _cards.isEmpty
          ? const Center(child: Text('No cards yet. Tap + to create one.'))
          : ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                final fields = Map<String, String>.from(
                    jsonDecode(card.fields) as Map<String, dynamic>);
                final values = fields.values.toList();
                return ListTile(
                  title: Text(values.isNotEmpty ? values[0] : ''),
                  subtitle: Text(values.length > 1 ? values[1] : ''),
                  trailing: Text(card.language),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardFormScreen(cardId: card.id),
                      ),
                    );
                    _loadCards();
                  },
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'generate',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const GenerateCardsScreen()),
              );
              _loadCards();
            },
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardFormScreen()),
              );
              _loadCards();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
