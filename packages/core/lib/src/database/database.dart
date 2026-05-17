import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Cards, FsrsStates, ReviewEvents, SavedFilters])
class RecallDatabase extends _$RecallDatabase {
  RecallDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
