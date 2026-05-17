// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
abstract class _$RecallDatabase extends GeneratedDatabase {
  _$RecallDatabase(QueryExecutor e) : super(e);
  $RecallDatabaseManager get managers => $RecallDatabaseManager(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
}

class $RecallDatabaseManager {
  final _$RecallDatabase _db;
  $RecallDatabaseManager(this._db);
}
