part of '../app_database.dart';

class EditorVersionRecords extends Table {
  @override
  String get tableName => 'editor_versions';

  TextColumn get id => text()();
  TextColumn get projectId => text().references(
        EditorProjectRecords,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get name => text()();
  TextColumn get stateJson => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
