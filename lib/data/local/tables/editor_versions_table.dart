part of '../app_database.dart';

class EditorVersionRecords extends Table {
  @override
  String get tableName => 'editor_versions';

  TextColumn get id => text()();
  IntColumn get projectId => integer().references(
        EditorProjectRecords,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get name => text()();
  TextColumn get parentVersionId => text().nullable()();
  TextColumn get stateJson => text()();
  TextColumn get historyJson => text().withDefault(
        const Constant(EditorHistorySnapshot.emptyJson),
      )();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get aiReferenceImagePath => text().nullable()();
  TextColumn get aiProfileId => text().nullable()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
