import 'package:drift/drift.dart';

class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get language => text()();
  TextColumn get fields => text()();
  TextColumn get fieldSpeakable => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class FsrsStates extends Table {
  IntColumn get cardId => integer().references(Cards, #id)();
  IntColumn get state => integer().withDefault(const Constant(1))();
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {cardId};
}

class ReviewEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(Cards, #id)();
  IntColumn get rating => integer()();
  TextColumn get studyMode => text().withDefault(const Constant('reading'))();
  TextColumn get direction =>
      text().withDefault(const Constant('source_to_target'))();
  IntColumn get audioReplayCount =>
      integer().withDefault(const Constant(0))();
  RealColumn get playbackSpeed =>
      real().withDefault(const Constant(1.0))();
  RealColumn get timeToRevealSeconds => real()();
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
}

class SavedFilters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get language => text().nullable()();
  TextColumn get tagQuery => text()();
  TextColumn get logicOperator =>
      text().withDefault(const Constant('and'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
