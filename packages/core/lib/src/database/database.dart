import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase()
class RecallDatabase extends _$RecallDatabase {
  RecallDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
