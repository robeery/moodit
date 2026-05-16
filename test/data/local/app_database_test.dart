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

    expect(database.schemaVersion, 2);
    expect(tableNames, containsAll(['editor_projects', 'editor_versions']));
    expect(projectColumnNames, contains('status'));
    expect(database.editorProjectsDao, isA<EditorProjectsDao>());
    expect(database.editorVersionsDao, isA<EditorVersionsDao>());
  });
}
