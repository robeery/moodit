part of '../app_database.dart';

class AiChatMessageRecords extends Table {
  @override
  String get tableName => 'ai_chat_messages';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(
        EditorProjectRecords,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get versionId => text().references(
        EditorVersionRecords,
        #id,
        onDelete: KeyAction.cascade,
      ).nullable()();
  TextColumn get type => text()();
  TextColumn get messageText => text().named('text')();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer()();
}
