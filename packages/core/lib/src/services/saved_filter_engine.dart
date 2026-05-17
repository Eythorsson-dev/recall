import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/database.dart';

class SavedFilterEngine {
  final RecallDatabase _db;

  SavedFilterEngine(this._db);

  Future<int> createFilter({
    required String name,
    String? language,
    required List<String> tags,
    String logicOperator = 'and',
  }) {
    return _db.into(_db.savedFilters).insert(
          SavedFiltersCompanion.insert(
            name: name,
            language: Value(language),
            tagQuery: jsonEncode(tags),
            logicOperator: Value(logicOperator),
          ),
        );
  }

  Future<List<SavedFilter>> getAllFilters() {
    return (_db.select(_db.savedFilters)
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  Future<void> deleteFilter(int id) {
    return (_db.delete(_db.savedFilters)
          ..where((f) => f.id.equals(id)))
        .go();
  }

  Future<List<Card>> applyFilter(SavedFilter filter) async {
    final allCards = await (_db.select(_db.cards)
          ..where((c) => c.deletedAt.isNull()))
        .get();

    final filterTags =
        (jsonDecode(filter.tagQuery) as List).cast<String>();

    return allCards.where((card) {
      if (filter.language != null && card.language != filter.language) {
        return false;
      }
      if (filterTags.isEmpty) return true;

      final cardTags =
          (jsonDecode(card.tags) as List).cast<String>();

      if (filter.logicOperator == 'or') {
        return filterTags.any((t) => cardTags.contains(t));
      } else {
        return filterTags.every((t) => cardTags.contains(t));
      }
    }).toList();
  }

  Future<List<String>> getAllTags() async {
    final allCards = await (_db.select(_db.cards)
          ..where((c) => c.deletedAt.isNull()))
        .get();

    final tags = <String>{};
    for (final card in allCards) {
      final cardTags =
          (jsonDecode(card.tags) as List).cast<String>();
      tags.addAll(cardTags);
    }

    final sorted = tags.toList()..sort();
    return sorted;
  }

  Future<List<Card>> getUntaggedCards() async {
    final allCards = await (_db.select(_db.cards)
          ..where((c) => c.deletedAt.isNull()))
        .get();

    return allCards.where((card) {
      final cardTags =
          (jsonDecode(card.tags) as List).cast<String>();
      return cardTags.isEmpty;
    }).toList();
  }

  List<String> fuzzyMatchTags(List<String> allTags, String query) {
    if (query.isEmpty) return allTags;
    final lower = query.toLowerCase();
    return allTags
        .where((t) => t.toLowerCase().contains(lower))
        .toList();
  }
}
