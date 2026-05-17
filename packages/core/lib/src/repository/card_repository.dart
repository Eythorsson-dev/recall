import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../database/database.dart';

class CardRepository {
  final RecallDatabase _db;

  CardRepository(this._db);

  Future<int> createCard({
    required String language,
    required Map<String, String> fields,
    required Map<String, bool> fieldSpeakable,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now().toUtc();
    final cardId = await _db.into(_db.cards).insert(CardsCompanion.insert(
          language: language,
          fields: jsonEncode(fields),
          fieldSpeakable: jsonEncode(fieldSpeakable),
          tags: Value(jsonEncode(tags)),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));

    await _db.into(_db.fsrsStates).insert(FsrsStatesCompanion.insert(
          cardId: Value(cardId),
          due: now,
        ));

    return cardId;
  }

  Future<Card?> getCard(int id) {
    return (_db.select(_db.cards)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Card>> getAllCards() {
    return (_db.select(_db.cards)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<void> updateCard(
    int id, {
    String? language,
    Map<String, String>? fields,
    Map<String, bool>? fieldSpeakable,
    List<String>? tags,
  }) async {
    final companion = CardsCompanion(
      language: language != null ? Value(language) : const Value.absent(),
      fields: fields != null ? Value(jsonEncode(fields)) : const Value.absent(),
      fieldSpeakable: fieldSpeakable != null
          ? Value(jsonEncode(fieldSpeakable))
          : const Value.absent(),
      tags: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );
    await (_db.update(_db.cards)..where((c) => c.id.equals(id)))
        .write(companion);
  }

  Future<void> softDeleteCard(int id) async {
    await (_db.update(_db.cards)..where((c) => c.id.equals(id))).write(
      CardsCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<FsrsState?> getFsrsState(int cardId) {
    return (_db.select(_db.fsrsStates)
          ..where((s) => s.cardId.equals(cardId)))
        .getSingleOrNull();
  }

  Future<void> updateFsrsState(int cardId, fsrs.Card fsrsCard) async {
    await (_db.update(_db.fsrsStates)
          ..where((s) => s.cardId.equals(cardId)))
        .write(FsrsStatesCompanion(
      state: Value(fsrsCard.state.value),
      step: Value(fsrsCard.step),
      stability: Value(fsrsCard.stability),
      difficulty: Value(fsrsCard.difficulty),
      due: Value(fsrsCard.due),
      lastReview: Value(fsrsCard.lastReview),
    ));
  }

  Future<List<CardWithFsrs>> getCardsDueToday() async {
    final now = DateTime.now().toUtc();
    final endOfDay = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

    final query = _db.select(_db.cards).join([
      innerJoin(
          _db.fsrsStates, _db.fsrsStates.cardId.equalsExp(_db.cards.id)),
    ])
      ..where(_db.cards.deletedAt.isNull() &
          _db.fsrsStates.due.isSmallerOrEqualValue(endOfDay))
      ..orderBy([OrderingTerm.asc(_db.fsrsStates.due)]);

    final rows = await query.get();
    return rows
        .map((row) => CardWithFsrs(
              card: row.readTable(_db.cards),
              fsrsState: row.readTable(_db.fsrsStates),
            ))
        .toList();
  }

  Future<int> recordReviewEvent({
    required int cardId,
    required int rating,
    required String studyMode,
    required String direction,
    required double timeToRevealSeconds,
    int audioReplayCount = 0,
    double playbackSpeed = 1.0,
  }) {
    return _db.into(_db.reviewEvents).insert(
          ReviewEventsCompanion.insert(
            cardId: cardId,
            rating: rating,
            studyMode: Value(studyMode),
            direction: Value(direction),
            audioReplayCount: Value(audioReplayCount),
            playbackSpeed: Value(playbackSpeed),
            timeToRevealSeconds: timeToRevealSeconds,
          ),
        );
  }

  Future<List<ReviewEvent>> getReviewEventsForCard(int cardId) {
    return (_db.select(_db.reviewEvents)
          ..where((e) => e.cardId.equals(cardId))
          ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
        .get();
  }
}

class CardWithFsrs {
  final Card card;
  final FsrsState fsrsState;

  const CardWithFsrs({required this.card, required this.fsrsState});
}
