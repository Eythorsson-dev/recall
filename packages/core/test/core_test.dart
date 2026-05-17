import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:test/test.dart';

import 'package:core/core.dart';

void main() {
  group('RecallDatabase', () {
    late RecallDatabase db;

    setUp(() {
      db = RecallDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('opens successfully with schema version 1', () {
      expect(db.schemaVersion, 1);
    });

    test('can execute a query against the empty database', () async {
      final result = await db.customSelect('SELECT 1 AS val').getSingle();
      expect(result.read<int>('val'), 1);
    });
  });

  group('CardRepository', () {
    late RecallDatabase db;
    late CardRepository repo;

    setUp(() {
      db = RecallDatabase(NativeDatabase.memory());
      repo = CardRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('CRUD', () {
      test('creates a card with language, fields, and speakable flags',
          () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'привіт', 'English': 'hello'},
          fieldSpeakable: {'Ukrainian': true, 'English': false},
        );

        final card = await repo.getCard(id);
        expect(card, isNotNull);
        expect(card!.language, 'Ukrainian');

        final fields = jsonDecode(card.fields) as Map<String, dynamic>;
        expect(fields['Ukrainian'], 'привіт');
        expect(fields['English'], 'hello');

        final speakable =
            jsonDecode(card.fieldSpeakable) as Map<String, dynamic>;
        expect(speakable['Ukrainian'], true);
        expect(speakable['English'], false);
      });

      test('creates a card with tags', () async {
        final id = await repo.createCard(
          language: 'Spanish',
          fields: {'Spanish': 'hola', 'English': 'hello'},
          fieldSpeakable: {'Spanish': true, 'English': false},
          tags: ['greetings', 'basics'],
        );

        final card = await repo.getCard(id);
        final tags = jsonDecode(card!.tags) as List<dynamic>;
        expect(tags, ['greetings', 'basics']);
      });

      test('card persists across reads', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'дякую', 'English': 'thank you'},
          fieldSpeakable: {'Ukrainian': true, 'English': false},
        );

        final cards = await repo.getAllCards();
        expect(cards.length, 1);
        expect(cards.first.id, id);
      });

      test('updates a card', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'привіт', 'English': 'hello'},
          fieldSpeakable: {'Ukrainian': true, 'English': false},
        );

        await repo.updateCard(id,
            fields: {'Ukrainian': 'привіт', 'English': 'hi'});

        final card = await repo.getCard(id);
        final fields = jsonDecode(card!.fields) as Map<String, dynamic>;
        expect(fields['English'], 'hi');
      });

      test('soft deletes a card', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'так', 'English': 'yes'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        await repo.softDeleteCard(id);

        final card = await repo.getCard(id);
        expect(card!.deletedAt, isNotNull);

        final allCards = await repo.getAllCards();
        expect(allCards, isEmpty);
      });
    });

    group('FSRS state', () {
      test('new card gets FSRS state with Learning status', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'ні', 'English': 'no'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        final state = await repo.getFsrsState(id);
        expect(state, isNotNull);
        expect(state!.state, fsrs.State.learning.value);
      });

      test('FSRS state is updated after review', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'добре', 'English': 'good'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        final scheduler = fsrs.Scheduler(enableFuzzing: false);
        final fsrsCard = fsrs.Card(cardId: id);
        final result =
            scheduler.reviewCard(fsrsCard, fsrs.Rating.good);

        await repo.updateFsrsState(id, result.card);

        final updated = await repo.getFsrsState(id);
        expect(updated!.stability, isNotNull);
        expect(updated.difficulty, isNotNull);
      });

      test('cards due today are returned', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'так', 'English': 'yes'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        final dueCards = await repo.getCardsDueToday();
        expect(dueCards.length, 1);
        expect(dueCards.first.card.id, id);
      });

      test('cards due in the future are not returned', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'ні', 'English': 'no'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        final scheduler = fsrs.Scheduler(enableFuzzing: false);
        final fsrsCard = fsrs.Card(cardId: id);
        final result = scheduler.reviewCard(
          fsrsCard,
          fsrs.Rating.good,
        );
        final result2 = scheduler.reviewCard(
          result.card,
          fsrs.Rating.easy,
        );
        await repo.updateFsrsState(id, result2.card);

        final dueCards = await repo.getCardsDueToday();
        expect(dueCards, isEmpty);
      });
    });

    group('Review events', () {
      test('records an immutable review event', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'так', 'English': 'yes'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        await repo.recordReviewEvent(
          cardId: id,
          rating: fsrs.Rating.good.value,
          studyMode: 'reading',
          direction: 'source_to_target',
          timeToRevealSeconds: 2.5,
        );

        final events = await repo.getReviewEventsForCard(id);
        expect(events.length, 1);
        expect(events.first.cardId, id);
        expect(events.first.rating, fsrs.Rating.good.value);
        expect(events.first.studyMode, 'reading');
        expect(events.first.direction, 'source_to_target');
        expect(events.first.timeToRevealSeconds, 2.5);
        expect(events.first.audioReplayCount, 0);
        expect(events.first.playbackSpeed, 1.0);
      });

      test('multiple review events are recorded in order', () async {
        final id = await repo.createCard(
          language: 'Ukrainian',
          fields: {'Ukrainian': 'так', 'English': 'yes'},
          fieldSpeakable: {'Ukrainian': false, 'English': false},
        );

        for (final rating in fsrs.Rating.values) {
          await repo.recordReviewEvent(
            cardId: id,
            rating: rating.value,
            studyMode: 'reading',
            direction: 'source_to_target',
            timeToRevealSeconds: 1.0,
          );
        }

        final events = await repo.getReviewEventsForCard(id);
        expect(events.length, 4);
      });
    });
  });

  group('FSRS scheduler', () {
    late fsrs.Scheduler scheduler;

    setUp(() {
      scheduler = fsrs.Scheduler(
        enableFuzzing: false,
      );
    });

    test('new card rated Good transitions through learning steps', () {
      var card = fsrs.Card(cardId: 1);
      expect(card.state, fsrs.State.learning);

      final r1 = scheduler.reviewCard(card, fsrs.Rating.good);
      card = r1.card;
      expect(card.stability, isNotNull);
      expect(card.difficulty, isNotNull);
    });

    test('all four ratings produce valid results', () {
      for (final rating in fsrs.Rating.values) {
        final card = fsrs.Card(cardId: rating.value);
        final result = scheduler.reviewCard(card, rating);
        expect(result.card.stability, isNotNull);
        expect(result.card.difficulty, isNotNull);
        expect(result.card.due.isAfter(DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            )), isTrue);
        expect(result.reviewLog.rating, rating);
      }
    });

    test('Again resets learning step', () {
      var card = fsrs.Card(cardId: 1);
      final r1 = scheduler.reviewCard(card, fsrs.Rating.good);
      card = r1.card;
      final r2 = scheduler.reviewCard(card, fsrs.Rating.again);
      card = r2.card;
      expect(card.state, fsrs.State.learning);
      expect(card.step, 0);
    });

    test('Easy on new card promotes to Review state', () {
      var card = fsrs.Card(cardId: 1);
      final result = scheduler.reviewCard(card, fsrs.Rating.easy);
      expect(result.card.state, fsrs.State.review);
    });

    test('retrievability decreases over time', () {
      final card = fsrs.Card(cardId: 1);
      final result = scheduler.reviewCard(card, fsrs.Rating.good);
      final reviewed = result.card;

      final r1 = scheduler.getCardRetrievability(
        reviewed,
        currentDateTime:
            reviewed.lastReview!.add(const Duration(days: 1)),
      );
      final r30 = scheduler.getCardRetrievability(
        reviewed,
        currentDateTime:
            reviewed.lastReview!.add(const Duration(days: 30)),
      );

      expect(r30, lessThan(r1));
    });
  });

  group('SavedFilterEngine', () {
    late RecallDatabase db;
    late CardRepository repo;
    late SavedFilterEngine engine;

    setUp(() {
      db = RecallDatabase(NativeDatabase.memory());
      repo = CardRepository(db);
      engine = SavedFilterEngine(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedCards() async {
      await repo.createCard(
        language: 'Ukrainian',
        fields: {'Ukrainian': 'привіт', 'English': 'hello'},
        fieldSpeakable: {'Ukrainian': true, 'English': false},
        tags: ['greetings', 'basics'],
      );
      await repo.createCard(
        language: 'Ukrainian',
        fields: {'Ukrainian': 'кухня', 'English': 'kitchen'},
        fieldSpeakable: {'Ukrainian': true, 'English': false},
        tags: ['kitchen', 'basics'],
      );
      await repo.createCard(
        language: 'Spanish',
        fields: {'Spanish': 'hola', 'English': 'hello'},
        fieldSpeakable: {'Spanish': true, 'English': false},
        tags: ['greetings'],
      );
      await repo.createCard(
        language: 'Ukrainian',
        fields: {'Ukrainian': 'вода', 'English': 'water'},
        fieldSpeakable: {'Ukrainian': true, 'English': false},
      );
    }

    test('AND filter matches cards with all tags', () async {
      await seedCards();
      await engine.createFilter(
        name: 'Ukrainian Basics',
        language: 'Ukrainian',
        tags: ['greetings', 'basics'],
        logicOperator: 'and',
      );

      final filters = await engine.getAllFilters();
      final results = await engine.applyFilter(filters.first);
      expect(results.length, 1);
      expect(results.first.language, 'Ukrainian');
    });

    test('OR filter matches cards with any tag', () async {
      await seedCards();
      await engine.createFilter(
        name: 'Greetings or Kitchen',
        language: 'Ukrainian',
        tags: ['greetings', 'kitchen'],
        logicOperator: 'or',
      );

      final filters = await engine.getAllFilters();
      final results = await engine.applyFilter(filters.first);
      expect(results.length, 2);
    });

    test('language-only filter returns all cards for language', () async {
      await seedCards();
      await engine.createFilter(
        name: 'All Ukrainian',
        language: 'Ukrainian',
        tags: [],
      );

      final filters = await engine.getAllFilters();
      final results = await engine.applyFilter(filters.first);
      expect(results.length, 3);
    });

    test('empty result when no cards match', () async {
      await seedCards();
      await engine.createFilter(
        name: 'Nonexistent',
        language: 'Ukrainian',
        tags: ['travel'],
      );

      final filters = await engine.getAllFilters();
      final results = await engine.applyFilter(filters.first);
      expect(results, isEmpty);
    });

    test('getAllTags returns sorted unique tags', () async {
      await seedCards();
      final tags = await engine.getAllTags();
      expect(tags, ['basics', 'greetings', 'kitchen']);
    });

    test('getUntaggedCards returns cards with no tags', () async {
      await seedCards();
      final untagged = await engine.getUntaggedCards();
      expect(untagged.length, 1);
      expect(untagged.first.language, 'Ukrainian');
    });

    test('fuzzyMatchTags filters by substring', () {
      final tags = ['greetings', 'grammar', 'kitchen', 'basics'];
      expect(engine.fuzzyMatchTags(tags, 'gr'),
          ['greetings', 'grammar']);
      expect(engine.fuzzyMatchTags(tags, 'kit'), ['kitchen']);
      expect(engine.fuzzyMatchTags(tags, ''), tags);
    });

    test('delete filter removes it', () async {
      final id = await engine.createFilter(
        name: 'Test',
        tags: ['test'],
      );
      var filters = await engine.getAllFilters();
      expect(filters.length, 1);

      await engine.deleteFilter(id);
      filters = await engine.getAllFilters();
      expect(filters, isEmpty);
    });
  });
}
