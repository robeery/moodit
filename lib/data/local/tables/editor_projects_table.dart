part of '../app_database.dart';

class EditorProjectRecords extends Table {
  @override
  String get tableName => 'editor_projects';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get activeVersionId => text().nullable()();
  TextColumn get originalImagePath => text()();
  TextColumn get previewImagePath => text().nullable()();
  TextColumn get currentStateJson => text()();
  IntColumn get originalWidth => integer()();
  IntColumn get originalHeight => integer()();
  IntColumn get previewWidth => integer()();
  IntColumn get previewHeight => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

}
