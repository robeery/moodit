import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/repositories/preset_repository.dart';
import 'package:licenta/model/rgba_image_frame.dart';
import 'package:licenta/services/preset_thumbnail_service.dart';
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

  test('builds and keeps in-memory thumbnails when a source frame is provided',
      () async {
    final repository = _FakePresetRepository()
      ..presets.add(_preset(id: 1, name: 'Portrait'));
    final thumbnailService = _FakePresetThumbnailService();
    final vm = PresetsViewModel(
      presetRepository: repository,
      thumbnailSourceFrame: _frame(),
      thumbnailService: thumbnailService,
    );
    addTearDown(vm.dispose);

    await vm.loadPresets();
    await Future<void>.delayed(Duration.zero);

    expect(thumbnailService.requestedPresetIds, [1]);
    expect(vm.thumbnailFor(vm.presets.single), Uint8List.fromList([1, 2, 3]));
    expect(vm.isLoadingThumbnails, isFalse);
  });

  test('loads a thumbnail source lazily when requested', () async {
    final repository = _FakePresetRepository()
      ..presets.add(_preset(id: 1, name: 'Portrait'));
    final thumbnailService = _FakePresetThumbnailService();
    var sourceLoadCount = 0;
    final vm = PresetsViewModel(
      presetRepository: repository,
      thumbnailSourceLoader: () async {
        sourceLoadCount++;
        return _frame();
      },
      thumbnailService: thumbnailService,
    );
    addTearDown(vm.dispose);

    expect(sourceLoadCount, 0);

    await vm.loadPresets();
    await Future<void>.delayed(Duration.zero);

    expect(sourceLoadCount, 1);
    expect(vm.thumbnailFor(vm.presets.single), Uint8List.fromList([1, 2, 3]));
  });
}

class _FakePresetThumbnailService extends PresetThumbnailService {
  final List<int> requestedPresetIds = [];

  @override
  Future<Map<int, Uint8List>> buildThumbnails({
    required RgbaImageFrame originalFrame,
    required List<EditorPreset> presets,
  }) async {
    requestedPresetIds.addAll(presets.map((preset) => preset.id));
    return {
      for (final preset in presets) preset.id: Uint8List.fromList([1, 2, 3]),
    };
  }
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

RgbaImageFrame _frame() {
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList([
      20, 40, 60, 255,
      80, 100, 120, 255,
      140, 160, 180, 255,
      200, 220, 240, 255,
    ]),
    width: 2,
    height: 2,
  );
}
