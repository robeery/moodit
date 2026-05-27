part of '../app_database.dart';

class EditorPresetRecords extends Table {
  @override
  String get tableName => 'editor_presets';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().unique()();
  TextColumn get stateJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
