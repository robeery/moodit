part of '../app_database.dart';

@DriftAccessor(tables: [EditorProjectRecords])
class EditorProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$EditorProjectsDaoMixin {
  EditorProjectsDao(super.db);

  Future<List<EditorProjectRecord>> loadRecentProjects({int limit = 20}) {
    final query = select(editorProjectRecords)
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
      ])
      ..limit(limit);

    return query.get();
  }

  Future<EditorProjectRecord?> findById(String id) {
    final query = select(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.getSingleOrNull();
  }

  Future<void> upsertProject(EditorProjectRecordsCompanion project) {
    return into(editorProjectRecords).insertOnConflictUpdate(project);
  }

  Future<int> deleteProject(String id) {
    final query = delete(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.go();
  }
}
