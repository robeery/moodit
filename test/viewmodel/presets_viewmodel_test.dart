import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/repositories/preset_repository.dart';
import 'package:licenta/viewmodel/presets_viewmodel.dart';

void main() {
  test('loads, renames, and deletes presets', () async {
    final repository = _FakePresetRepository()
      ..presets.add(_preset(id: 1, name: 'Portrait'));
    final vm = PresetsViewModel(presetRepository: repository);
    addTearDown(vm.dispose);

    await vm.loadPresets();
    expect(vm.presets.single.name, 'Portrait');

    expect(await vm.renamePreset(vm.presets.single, 'Soft portrait'), isTrue);
    expect(vm.presets.single.name, 'Soft portrait');

    expect(await vm.deletePreset(vm.presets.single), isTrue);
    expect(vm.isEmpty, isTrue);
  });

  test('exposes repository errors', () async {
    final repository = _FakePresetRepository()
      ..presets.add(_preset(id: 1, name: 'Portrait'))
      ..renameError = const PresetConflictException(
        'A preset with this name already exists.',
      );
    final vm = PresetsViewModel(presetRepository: repository);
    addTearDown(vm.dispose);

    await vm.loadPresets();

    expect(await vm.renamePreset(vm.presets.single, 'Duplicate'), isFalse);
    expect(vm.errorMessage, 'A preset with this name already exists.');

    vm.clearError();
    expect(vm.errorMessage, isNull);
  });
}

class _FakePresetRepository implements PresetRepository {
  final List<EditorPreset> presets = [];
  PresetRepositoryException? renameError;

  @override
  Future<EditorPreset> createPreset({
    required String name,
    required EditorEditState state,
    required DateTime createdAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePreset(int id) async {
    presets.removeWhere((preset) => preset.id == id);
  }

  @override
  Future<List<EditorPreset>> loadPresets() async => List.of(presets);

  @override
  Future<EditorPreset> renamePreset({
    required int id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final error = renameError;
    if (error != null) throw error;

    final index = presets.indexWhere((preset) => preset.id == id);
    final current = presets[index];
    final renamed = EditorPreset(
      id: current.id,
      name: name,
      state: current.state,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
    presets[index] = renamed;
    return renamed;
  }
}

EditorPreset _preset({
  required int id,
  required String name,
}) {
  final now = DateTime.utc(2026, 6, 1);
  return EditorPreset(
    id: id,
    name: name,
    state: EditorEditState(
      edits: [Edit(type: OperationType.contrast, value: 10)],
      colorEdits: const [],
      colorGradingEdits: const [],
    ),
    createdAt: now,
    updatedAt: now,
  );
}
