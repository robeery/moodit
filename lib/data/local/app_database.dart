import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(
              editorProjectRecords,
              editorProjectRecords.status,
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
