import '../data/local/app_database.dart';
import '../data/local/mappers/editor_preset_record_mapper.dart';
import '../model/editor_edit_state.dart';
import '../model/editor_preset.dart';
import 'preset_repository.dart';

class DriftPresetRepository implements PresetRepository {
  DriftPresetRepository(AppDatabase database)
      : _store = DriftPresetRecordStore(database.editorPresetsDao);

  DriftPresetRepository.withStore(this._store);

  final PresetRecordStore _store;

  @override
  Future<List<EditorPreset>> loadPresets() async {
    return _store.loadAll();
  }

  @override
  Future<EditorPreset> createPreset({
    required String name,
    required EditorEditState state,
    required DateTime createdAt,
  }) async {
    final trimmedName = _validateName(name);
    final compactState = state.activeOnly();
    if (compactState.isEmpty) {
      throw const PresetValidationException(
        'Cannot save a preset without edits.',
      );
    }

    final normalizedName = normalizeEditorPresetName(trimmedName);
    await _ensureNameIsAvailable(normalizedName);
    final preset = EditorPreset(
      id: 0,
      name: trimmedName,
      state: compactState,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    try {
      return await _store.insertPreset(preset);
    } catch (_) {
      await _throwConflictIfPresent(normalizedName);
      rethrow;
    }
  }

  @override
  Future<EditorPreset> renamePreset({
    required int id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final current = await _store.findById(id);
    if (current == null) throw const PresetNotFoundException();

    final trimmedName = _validateName(name);
    final normalizedName = normalizeEditorPresetName(trimmedName);
    await _ensureNameIsAvailable(normalizedName, exceptId: id);

    try {
      await _store.renamePreset(
        id: id,
        name: trimmedName,
        normalizedName: normalizedName,
        updatedAt: updatedAt,
      );
    } catch (_) {
      await _throwConflictIfPresent(normalizedName, exceptId: id);
      rethrow;
    }

    final updated = await _store.findById(id);
    if (updated == null) throw const PresetNotFoundException();
    return updated;
  }

  @override
  Future<void> deletePreset(int id) async {
    await _store.deletePreset(id);
  }

  String _validateName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const PresetValidationException('Preset name cannot be empty.');
    }
    if (trimmedName.length > editorPresetNameMaxLength) {
      throw const PresetValidationException(
        'Preset name must be at most 32 characters.',
      );
    }
    return trimmedName;
  }

  Future<void> _ensureNameIsAvailable(
    String normalizedName, {
    int? exceptId,
  }) async {
    final existing = await _store.findByNormalizedName(normalizedName);
    if (existing != null && existing.id != exceptId) {
      throw const PresetConflictException(
        'A preset with this name already exists.',
      );
    }
  }

  Future<void> _throwConflictIfPresent(
    String normalizedName, {
    int? exceptId,
  }) async {
    await _ensureNameIsAvailable(normalizedName, exceptId: exceptId);
  }
}

abstract class PresetRecordStore {
  Future<List<EditorPreset>> loadAll();
  Future<EditorPreset?> findById(int id);
  Future<EditorPreset?> findByNormalizedName(String normalizedName);
  Future<EditorPreset> insertPreset(EditorPreset preset);
  Future<void> renamePreset({
    required int id,
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  });
  Future<void> deletePreset(int id);
}

class DriftPresetRecordStore implements PresetRecordStore {
  const DriftPresetRecordStore(this._dao);

  final EditorPresetsDao _dao;

  @override
  Future<List<EditorPreset>> loadAll() async {
    final records = await _dao.loadAll();
    return records.map((record) => record.toModel()).toList();
  }

  @override
  Future<EditorPreset?> findById(int id) async {
    return (await _dao.findById(id))?.toModel();
  }

  @override
  Future<EditorPreset?> findByNormalizedName(String normalizedName) async {
    return (await _dao.findByNormalizedName(normalizedName))?.toModel();
  }

  @override
  Future<EditorPreset> insertPreset(EditorPreset preset) async {
    return (await _dao.insertPreset(preset.toRecordCompanion())).toModel();
  }

  @override
  Future<void> renamePreset({
    required int id,
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  }) async {
    await _dao.renamePreset(
      id: id,
      name: name,
      normalizedName: normalizedName,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> deletePreset(int id) async {
    await _dao.deletePreset(id);
  }
}
