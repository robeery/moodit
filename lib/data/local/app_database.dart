import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../model/editor_history_snapshot.dart';

part 'tables/ai_chat_messages_table.dart';
part 'tables/editor_projects_table.dart';
part 'tables/editor_presets_table.dart';
part 'tables/editor_versions_table.dart';
part 'daos/ai_chat_messages_dao.dart';
part 'daos/editor_projects_dao.dart';
part 'daos/editor_presets_dao.dart';
part 'daos/editor_versions_dao.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AiChatMessageRecords,
    EditorProjectRecords,
    EditorPresetRecords,
    EditorVersionRecords,
  ],
  daos: [
    AiChatMessagesDao,
    EditorProjectsDao,
    EditorPresetsDao,
    EditorVersionsDao,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'moodit_editor'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.deleteTable(editorVersionRecords.actualTableName);
            await m.deleteTable(editorProjectRecords.actualTableName);
            await m.createTable(editorProjectRecords);
            await m.createTable(editorVersionRecords);
            await m.createTable(aiChatMessageRecords);
            await m.createTable(editorPresetRecords);
            return;
          }
          if (from < 4) {
            if (!await _hasColumn('editor_projects', 'active_version_id')) {
              await m.addColumn(
                editorProjectRecords,
                editorProjectRecords.activeVersionId,
              );
            }
            if (!await _hasColumn('editor_versions', 'parent_version_id')) {
              await m.addColumn(
                editorVersionRecords,
                editorVersionRecords.parentVersionId,
              );
            }
            if (!await _hasColumn('editor_versions', 'history_json')) {
              await m.addColumn(
                editorVersionRecords,
                editorVersionRecords.historyJson,
              );
            }
          }
          if (from < 5) {
            await m.createTable(aiChatMessageRecords);
          }
          if (from < 6) {
            await m.createTable(editorPresetRecords);
          }
          if (from < 7) {
            if (!await _hasColumn('editor_versions', 'ai_reference_image_path')) {
              await m.addColumn(
                editorVersionRecords,
                editorVersionRecords.aiReferenceImagePath,
              );
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<bool> _hasColumn(String tableName, String columnName) async {
    final columns = await customSelect('PRAGMA table_info($tableName)').get();
    return columns.any((row) => row.data['name'] == columnName);
  }
}
