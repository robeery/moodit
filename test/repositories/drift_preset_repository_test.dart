import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/repositories/drift_preset_repository.dart';
import 'package:licenta/repositories/preset_repository.dart';

void main() {
  late _MemoryPresetRecordStore store;
  late DriftPresetRepository repository;

  setUp(() {
    store = _MemoryPresetRecordStore();
    repository = DriftPresetRepository.withStore(store);
  });

  test('creates, loads, renames, orders, and deletes presets', () async {
    final first = await repository.createPreset(
      name: 'Warm',
      state: _state(OperationType.warmth, 10),
      createdAt: DateTime(2026, 6, 1, 10),
    );
    final second = await repository.createPreset(
      name: 'Contrast',
      state: _state(OperationType.contrast, 20),
      createdAt: DateTime(2026, 6, 1, 11),
    );

    expect((await repository.loadPresets()).map((preset) => preset.name), [
      'Contrast',
      'Warm',
    ]);

    final renamed = await repository.renamePreset(
      id: first.id,
      name: '  Warm Portrait  ',
      updatedAt: DateTime(2026, 6, 1, 12),
    );

    expect(renamed.name, 'Warm Portrait');
    expect((await repository.loadPresets()).map((preset) => preset.id), [
      first.id,
      second.id,
    ]);

    await repository.deletePreset(second.id);
    expect((await repository.loadPresets()).single.id, first.id);
  });

  test('rejects empty state, long names, and case-insensitive duplicates', () async {
    expect(
      () => repository.createPreset(
        name: 'Empty',
        state: EditorEditState.empty(),
        createdAt: DateTime(2026, 6, 1),
      ),
      throwsA(isA<PresetValidationException>()),
    );
    expect(
      () => repository.createPreset(
        name: 'x' * 33,
        state: _state(OperationType.exposure, 5),
        createdAt: DateTime(2026, 6, 1),
      ),
      throwsA(isA<PresetValidationException>()),
    );

    await repository.createPreset(
      name: 'Portrait',
      state: _state(OperationType.exposure, 5),
      createdAt: DateTime(2026, 6, 1),
    );

    expect(
      () => repository.createPreset(
        name: '  PORTRAIT ',
        state: _state(OperationType.exposure, 8),
        createdAt: DateTime(2026, 6, 1),
      ),
      throwsA(isA<PresetConflictException>()),
    );
  });
}

EditorEditState _state(OperationType type, double value) {
  return EditorEditState(
    edits: [Edit(type: type, value: value)],
    colorEdits: const [],
    colorGradingEdits: const [],
  );
}

class _MemoryPresetRecordStore implements PresetRecordStore {
  final List<EditorPreset> _presets = [];
  int _nextId = 1;

  @override
  Future<List<EditorPreset>> loadAll() async {
    final result = List<EditorPreset>.of(_presets);
    result.sort((a, b) {
      final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdatedAt != 0) return byUpdatedAt;
      return b.id.compareTo(a.id);
    });
    return result;
  }

  @override
  Future<EditorPreset?> findById(int id) async {
    return _presets.where((preset) => preset.id == id).firstOrNull;
  }

  @override
  Future<EditorPreset?> findByNormalizedName(String normalizedName) async {
    return _presets
        .where((preset) => normalizeEditorPresetName(preset.name) == normalizedName)
        .firstOrNull;
  }

  @override
  Future<EditorPreset> insertPreset(EditorPreset preset) async {
    final stored = EditorPreset(
      id: _nextId++,
      name: preset.name,
      state: preset.state,
      createdAt: preset.createdAt,
      updatedAt: preset.updatedAt,
    );
    _presets.add(stored);
    return stored;
  }

  @override
  Future<void> renamePreset({
    required int id,
    required String name,
    required String normalizedName,
    required DateTime updatedAt,
  }) async {
    final index = _presets.indexWhere((preset) => preset.id == id);
    if (index < 0) return;
    final current = _presets[index];
    _presets[index] = EditorPreset(
      id: current.id,
      name: name,
      state: current.state,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> deletePreset(int id) async {
    _presets.removeWhere((preset) => preset.id == id);
  }
}
