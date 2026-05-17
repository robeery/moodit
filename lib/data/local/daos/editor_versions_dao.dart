part of '../app_database.dart';

@DriftAccessor(tables: [EditorVersionRecords])
class EditorVersionsDao extends DatabaseAccessor<AppDatabase>
    with _$EditorVersionsDaoMixin {
  EditorVersionsDao(super.db);

  Future<List<EditorVersionRecord>> loadForProject(int projectId) {
    final query = select(editorVersionRecords)
      ..where((table) => table.projectId.equals(projectId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);

    return query.get();
  }

  Future<EditorVersionRecord?> findById(String id) {
    final query = select(editorVersionRecords)
      ..where((table) => table.id.equals(id));

    return query.getSingleOrNull();
  }

  Future<void> upsertVersion(EditorVersionRecordsCompanion version) {
    return into(editorVersionRecords).insertOnConflictUpdate(version);
  }

  Future<int> deleteVersion(String id) {
    final query = delete(editorVersionRecords)
      ..where((table) => table.id.equals(id));

    return query.go();
  }

  Future<int> deleteVersionsForProject(int projectId) {
    final query = delete(editorVersionRecords)
      ..where((table) => table.projectId.equals(projectId));

    return query.go();
  }
}
