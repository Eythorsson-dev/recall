import 'package:drift/drift.dart';

import '../database/database.dart';

class ProgressStats {
  final int streak;
  final bool streakFreezeAvailable;
  final int wordsLearned;
  final int sessionProgress;
  final int sessionTotal;

  const ProgressStats({
    required this.streak,
    required this.streakFreezeAvailable,
    required this.wordsLearned,
    required this.sessionProgress,
    required this.sessionTotal,
  });
}

class ProgressTracker {
  final RecallDatabase _db;

  ProgressTracker(this._db);

  Future<ProgressStats> getStats({int dailyNewCardLimit = 10}) async {
    final streak = await _calculateStreak();
    final wordsLearned = await _calculateWordsLearned();
    final todayReviewed = await _getTodayReviewedCardCount();
    final totalDue = await _getTotalDueToday();

    return ProgressStats(
      streak: streak.days,
      streakFreezeAvailable: streak.missedYesterday,
      wordsLearned: wordsLearned,
      sessionProgress: todayReviewed,
      sessionTotal: totalDue,
    );
  }

  Future<({int days, bool missedYesterday})> _calculateStreak() async {
    final events = await (_db.select(_db.reviewEvents)
          ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
        .get();

    if (events.isEmpty) return (days: 0, missedYesterday: false);

    final reviewDays = <DateTime>{};
    for (final event in events) {
      final d = event.timestamp;
      reviewDays.add(DateTime.utc(d.year, d.month, d.day));
    }

    final sortedDays = reviewDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now().toUtc();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    int streak = 0;
    bool missedYesterday = false;

    DateTime checkDate;
    if (sortedDays.first == todayDate) {
      checkDate = todayDate;
    } else if (sortedDays.first == yesterdayDate) {
      checkDate = yesterdayDate;
      missedYesterday = false;
    } else {
      final daysBetween = todayDate.difference(sortedDays.first).inDays;
      if (daysBetween == 1) {
        missedYesterday = true;
      }
      return (days: 0, missedYesterday: missedYesterday);
    }

    for (final day in sortedDays) {
      if (day == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (day.isBefore(checkDate)) {
        break;
      }
    }

    if (!sortedDays.contains(todayDate) &&
        sortedDays.contains(yesterdayDate)) {
      missedYesterday = false;
    }

    return (days: streak, missedYesterday: missedYesterday);
  }

  Future<int> _calculateWordsLearned() async {
    final events = await _db.select(_db.reviewEvents).get();

    final learnedCardIds = <int>{};
    for (final event in events) {
      if (event.rating >= 3) {
        learnedCardIds.add(event.cardId);
      }
    }

    return learnedCardIds.length;
  }

  Future<int> _getTodayReviewedCardCount() async {
    final today = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(today.year, today.month, today.day);

    final events = await (_db.select(_db.reviewEvents)
          ..where(
              (e) => e.timestamp.isBiggerOrEqualValue(startOfDay)))
        .get();

    return events.map((e) => e.cardId).toSet().length;
  }

  Future<int> _getTotalDueToday() async {
    final now = DateTime.now().toUtc();
    final endOfDay = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

    final query = _db.select(_db.cards).join([
      innerJoin(
          _db.fsrsStates, _db.fsrsStates.cardId.equalsExp(_db.cards.id)),
    ])
      ..where(_db.cards.deletedAt.isNull() &
          _db.fsrsStates.due.isSmallerOrEqualValue(endOfDay));

    final rows = await query.get();
    return rows.length;
  }
}
