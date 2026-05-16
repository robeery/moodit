import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/model/ai_profile_settings.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/services/ai_profiles_api_key_storage.dart';
import 'package:licenta/services/ai_profiles_storage.dart';
import 'package:licenta/services/project_file_store.dart';
import 'package:licenta/viewmodel/editor_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const connectivityStatusChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity_status');

  test('manual edit can be undone and redone', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    addTearDown(() async {
      final parent = sourceFile.parent;
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
    );
    addTearDown(vm.dispose);

    await vm.loadImageFromPath(sourceFile.path);
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 30));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 30));

    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(vm.canUndo, isTrue);
    expect(vm.canRedo, isFalse);

    final undoResult = await vm.undo();
    expect(undoResult?.label, 'Brightness +30');
    expect(vm.getEditValue(OperationType.brightness), 0);
    expect(vm.canRedo, isTrue);

    final redoResult = await vm.redo();
    expect(redoResult?.label, 'Brightness +30');
    expect(vm.getEditValue(OperationType.brightness), 30);
  });

  test('import image creates persisted project from app-owned original', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final tempDir = sourceFile.parent;
    final repository = _FakeEditorProjectRepository();
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
      now: () => DateTime.utc(2026, 5, 16, 12),
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.importImageAsProject(sourceFile.path);

    final project = vm.currentProject;
    expect(project, isNotNull);
    expect(project!.name, 'source');
    expect(project.status, EditorProjectStatus.draft);
    expect(project.originalImagePath, isNot(sourceFile.path));
    expect(project.originalImagePath, vm.originalImagePath);
    expect(await File(project.originalImagePath).exists(), isTrue);
    expect(project.originalWidth, 16);
    expect(project.originalHeight, 16);
    expect(project.previewWidth, 16);
    expect(project.previewHeight, 16);
    expect(repository.savedProjects.single.originalImagePath,
        project.originalImagePath);
    expect(repository.savedProjects.single.status, EditorProjectStatus.draft);
    expect(
      repository.savedProjects.single.currentState
          .contentEquals(EditorEditState.empty()),
      isTrue,
    );

    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 30));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 30));

    expect(repository.savedStates.single.projectId, project.id);
    expect(repository.savedStates.single.state.edits.single.type,
        OperationType.brightness);
    expect(repository.savedStates.single.state.edits.single.value, 30);

    final saved = await vm.saveCurrentDraftAsProject('Portrait edit');

    expect(saved, isTrue);
    expect(vm.currentProject?.name, 'Portrait edit');
    expect(vm.currentProject?.status, EditorProjectStatus.saved);
    expect(repository.promotedProjects.single.projectId, project.id);
    expect(repository.promotedProjects.single.name, 'Portrait edit');
    expect(repository.promotedProjects.single.state.edits.single.value, 30);
  });

  test('load project restores persisted edit state', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    addTearDown(() async {
      final parent = sourceFile.parent;
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });
    final savedAt = DateTime.utc(2026, 5, 16, 11);
    final openedAt = DateTime.utc(2026, 5, 16, 12);
    final repository = _FakeEditorProjectRepository();
    repository.savedProjects.add(EditorProject(
      id: 'project_1',
      name: 'Loaded project',
      status: EditorProjectStatus.saved,
      originalImagePath: sourceFile.path,
      currentState: EditorEditState(
        edits: [Edit(type: OperationType.brightness, value: 30)],
        colorEdits: const [],
        colorGradingEdits: const [],
      ),
      originalWidth: 16,
      originalHeight: 16,
      previewWidth: 16,
      previewHeight: 16,
      createdAt: savedAt,
      updatedAt: savedAt,
      lastOpenedAt: savedAt,
    ));
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      projectRepository: repository,
      now: () => openedAt,
    );
    addTearDown(vm.dispose);

    final loaded = await vm.loadProject('project_1');

    expect(loaded, isTrue);
    expect(vm.currentProject?.id, 'project_1');
    expect(vm.currentProject?.lastOpenedAt, openedAt);
    expect(vm.originalImagePath, sourceFile.path);
    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(repository.openedProjects.single.projectId, 'project_1');
    expect(repository.openedProjects.single.openedAt, openedAt);
  });
}

Future<File> _createTempImage() async {
  final tempDir = await Directory.systemTemp.createTemp('moodit_history_test_');
  final image = img.Image(width: 16, height: 16, numChannels: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, 40 + x, 70 + y, 120, 255);
    }
  }

  final sourceFile = File('${tempDir.path}/source.png');
  await sourceFile.writeAsBytes(Uint8List.fromList(img.encodePng(image)));
  return sourceFile;
}

class _FakeAiProfilesStorage extends AiProfilesStorage {
  @override
  Future<PersistedAiProfiles?> load() async => null;

  @override
  Future<void> save({
    required List<AiProfileSettings> profiles,
    required String activeProfileId,
  }) async {}
}

class _FakeAiProfilesApiKeyStorage extends AiProfilesApiKeyStorage {
  const _FakeAiProfilesApiKeyStorage();

  @override
  Future<Map<String, String>> readMany(Iterable<String> profileIds) async => {};

  @override
  Future<void> saveForProfiles({
    required Map<String, String> apiKeysByProfileId,
    required Set<String> validProfileIds,
  }) async {}
}

class _SavedState {
  const _SavedState({
    required this.projectId,
    required this.state,
    required this.updatedAt,
  });

  final String projectId;
  final EditorEditState state;
  final DateTime updatedAt;
}

class _OpenedProject {
  const _OpenedProject({
    required this.projectId,
    required this.openedAt,
  });

  final String projectId;
  final DateTime openedAt;
}

class _PromotedProject {
  const _PromotedProject({
    required this.projectId,
    required this.name,
    required this.state,
    required this.updatedAt,
  });

  final String projectId;
  final String name;
  final EditorEditState state;
  final DateTime updatedAt;
}

class _FakeEditorProjectRepository implements EditorProjectRepository {
  final List<EditorProject> savedProjects = [];
  final List<_SavedState> savedStates = [];
  final List<_OpenedProject> openedProjects = [];
  final List<_PromotedProject> promotedProjects = [];

  @override
  Future<void> deleteProject(String id) async {}

  @override
  Future<void> deleteVersion(String id) async {}

  @override
  Future<EditorProject?> loadProject(String id) async {
    return savedProjects.where((project) => project.id == id).firstOrNull;
  }

  @override
  Future<List<EditorProject>> loadRecentProjects({int limit = 20}) async {
    return savedProjects
        .where((project) => project.status == EditorProjectStatus.saved)
        .take(limit)
        .toList();
  }

  @override
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20}) async {
    return savedProjects
        .where((project) => project.status == EditorProjectStatus.draft)
        .take(limit)
        .toList();
  }

  @override
  Future<EditorVersion?> loadVersion(String id) async => null;

  @override
  Future<List<EditorVersion>> loadVersions(String projectId) async => [];

  @override
  Future<void> markProjectOpened({
    required String projectId,
    required DateTime openedAt,
  }) async {
    openedProjects.add(_OpenedProject(
      projectId: projectId,
      openedAt: openedAt,
    ));
  }

  @override
  Future<void> promoteDraftToSaved({
    required String projectId,
    required String name,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    promotedProjects.add(_PromotedProject(
      projectId: projectId,
      name: name,
      state: state,
      updatedAt: updatedAt,
    ));
    final index = savedProjects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    savedProjects[index] = savedProjects[index].copyWith(
      name: name,
      status: EditorProjectStatus.saved,
      currentState: state,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> saveCurrentState({
    required String projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    savedStates.add(_SavedState(
      projectId: projectId,
      state: state,
      updatedAt: updatedAt,
    ));
  }

  @override
  Future<void> saveProject(EditorProject project) async {
    savedProjects.add(project);
  }

  @override
  Future<void> saveVersion(EditorVersion version) async {}
}
