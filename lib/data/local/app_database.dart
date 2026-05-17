import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../model/editor_history_snapshot.dart';

part 'tables/editor_projects_table.dart';
part 'tables/editor_versions_table.dart';
part 'daos/editor_projects_dao.dart';
part 'daos/editor_versions_dao.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    EditorProjectRecords,
    EditorVersionRecords,
  ],
  daos: [
    EditorProjectsDao,
    EditorVersionsDao,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'moodit_editor'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.deleteTable(editorVersionRecords.actualTableName);
            await m.deleteTable(editorProjectRecords.actualTableName);
            await m.createTable(editorProjectRecords);
            await m.createTable(editorVersionRecords);
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
