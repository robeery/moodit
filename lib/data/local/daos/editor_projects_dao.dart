part of '../app_database.dart';

@DriftAccessor(tables: [EditorProjectRecords])
class EditorProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$EditorProjectsDaoMixin {
  EditorProjectsDao(super.db);

  Future<List<EditorProjectRecord>> loadRecentProjects({
    required String status,
    int limit = 20,
  }) {
    final query = select(editorProjectRecords)
      ..where((table) => table.status.equals(status))
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
      ])
      ..limit(limit);

    return query.get();
  }

  Future<EditorProjectRecord?> findById(int id) {
    final query = select(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.getSingleOrNull();
  }

  Future<int> upsertProject(EditorProjectRecordsCompanion project) {
    return into(editorProjectRecords).insertOnConflictUpdate(project);
  }

  Future<int> updateCurrentState({
    required int id,
    required String currentStateJson,
    required DateTime updatedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      currentStateJson: Value(currentStateJson),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> updatePreviewPath({
    required int id,
    required String previewImagePath,
    required DateTime updatedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      previewImagePath: Value(previewImagePath),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> updateActiveVersion({
    required int id,
    required String? activeVersionId,
    required String currentStateJson,
    required DateTime updatedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      activeVersionId: Value(activeVersionId),
      currentStateJson: Value(currentStateJson),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> markOpened({
    required int id,
    required DateTime openedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      lastOpenedAt: Value(openedAt),
    ));
  }

  Future<int> promoteDraftToSaved({
    required int id,
    required String name,
    required String savedStatus,
    required String currentStateJson,
    required DateTime updatedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      name: Value(name),
      status: Value(savedStatus),
      currentStateJson: Value(currentStateJson),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> renameProject({
    required int id,
    required String name,
    required DateTime updatedAt,
  }) {
    final query = update(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorProjectRecordsCompanion(
      name: Value(name),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> deleteProject(int id) {
    final query = delete(editorProjectRecords)
      ..where((table) => table.id.equals(id));

    return query.go();
  }
}
