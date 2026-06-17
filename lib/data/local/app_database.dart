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
  int get schemaVersion => 1;

  // Fresh 1.0 schema. New installs build every table via the default onCreate
  // (createAll); there is no prior version to upgrade from. beforeOpen still
  // runs on every open to enforce foreign keys.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
