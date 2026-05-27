import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/data/local/app_database.dart';

void main() {
  test('defines project persistence schema', () async {
    final database = AppDatabase(LazyDatabase(() {
      throw UnsupportedError('The schema test should not open sqlite.');
    }));
    addTearDown(database.close);

    final tableNames = database.allTables.map((table) => table.actualTableName);
	    final projectColumnNames =
	        database.editorProjectRecords.$columns.map((column) => column.$name);
	    final versionColumnNames =
	        database.editorVersionRecords.$columns.map((column) => column.$name);

	    final aiMessageColumnNames =
	        database.aiChatMessageRecords.$columns.map((column) => column.$name);
	    final presetColumnNames =
	        database.editorPresetRecords.$columns.map((column) => column.$name);

	    expect(database.schemaVersion, 6);
	    expect(tableNames, containsAll([
	      'editor_projects',
	      'editor_versions',
	      'ai_chat_messages',
	      'editor_presets',
	    ]));
	    expect(projectColumnNames, contains('status'));
	    expect(projectColumnNames, contains('active_version_id'));
	    expect(versionColumnNames, contains('parent_version_id'));
	    expect(versionColumnNames, contains('history_json'));
	    expect(aiMessageColumnNames, contains('project_id'));
	    expect(aiMessageColumnNames, contains('version_id'));
	    expect(aiMessageColumnNames, contains('sort_order'));
	    expect(presetColumnNames, containsAll([
	      'id',
	      'name',
	      'normalized_name',
	      'state_json',
	      'created_at',
	      'updated_at',
	    ]));
	    expect(database.aiChatMessagesDao, isA<AiChatMessagesDao>());
	    expect(database.editorProjectsDao, isA<EditorProjectsDao>());
	    expect(database.editorPresetsDao, isA<EditorPresetsDao>());
    expect(database.editorVersionsDao, isA<EditorVersionsDao>());
  });

}
