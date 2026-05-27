part of '../app_database.dart';

@DriftAccessor(tables: [EditorPresetRecords])
class EditorPresetsDao extends DatabaseAccessor<AppDatabase>
    with _$EditorPresetsDaoMixin {
  EditorPresetsDao(super.db);

  Future<List<EditorPresetRecord>> loadAll() {
    final query = select(editorPresetRecords)
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.id),
      ]);

    return query.get();
  }

  Future<EditorPresetRecord?> findById(int id) {
    final query = select(editorPresetRecords)
      ..where((table) => table.id.equals(id));

    return query.getSingleOrNull();
  }

  Future<EditorPresetRecord?> findByNormalizedName(String normalizedName) {
    final query = select(editorPresetRecords)
      ..where((table) => table.normalizedName.equals(normalizedName));

    return query.getSingleOrNull();
  }

  Future<EditorPresetRecord> insertPreset(
    EditorPresetRecordsCompanion preset,
  ) {
    return into(editorPresetRecords).insertReturning(preset);
  }

  Future<int> renamePreset({
    required int id,
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  }) {
    final query = update(editorPresetRecords)
      ..where((table) => table.id.equals(id));

    return query.write(EditorPresetRecordsCompanion(
      name: Value(name),
      normalizedName: Value(normalizedName),
      updatedAt: Value(updatedAt),
    ));
  }

  Future<int> deletePreset(int id) {
    final query = delete(editorPresetRecords)
      ..where((table) => table.id.equals(id));

    return query.go();
  }
}
