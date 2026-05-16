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

    expect(database.schemaVersion, 1);
    expect(tableNames, containsAll(['editor_projects', 'editor_versions']));
    expect(database.editorProjectsDao, isA<EditorProjectsDao>());
    expect(database.editorVersionsDao, isA<EditorVersionsDao>());
  });
}
