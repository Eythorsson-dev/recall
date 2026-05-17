import 'package:drift/native.dart';
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
}
