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
    expect(project!.id, 1);
    expect(project.name, 'source');
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
    expect(vm.versions, hasLength(1));
    expect(vm.activeVersion?.name, 'Version 1');
    expect(vm.currentProject?.activeVersionId, vm.activeVersion?.id);
    expect(repository.savedVersions.single.name, 'Version 1');
    expect(
      repository.savedProjects.single.currentState
          .contentEquals(EditorEditState.empty()),
      isTrue,
    );
    final initialPreviewPath = repository.savedProjects.single.previewImagePath;
    expect(initialPreviewPath, isNotNull);
    expect(initialPreviewPath, contains('preview_'));
    expect(await File(initialPreviewPath!).exists(), isTrue);

    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 30));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 30));

    expect(repository.savedVersions.single.projectId, project.id);
    expect(repository.savedVersions.single.state.edits.single.type,
        OperationType.brightness);
    expect(repository.savedVersions.single.state.edits.single.value, 30);
    expect(repository.savedProjects.single.currentState.edits.single.value, 30);
    expect(repository.updatedPreviewPaths, isNotEmpty);
    expect(repository.savedProjects.single.previewImagePath,
        repository.updatedPreviewPaths.last);
    expect(await File(repository.updatedPreviewPaths.last).exists(), isTrue);
    expect(repository.updatedPreviewPaths.last, isNot(initialPreviewPath));

    final saved = await vm.saveCurrentDraftAsProject('Portrait edit');

    expect(saved, isTrue);
    expect(vm.currentProject?.name, 'Portrait edit');
    expect(vm.currentProject?.status, EditorProjectStatus.saved);
    expect(repository.promotedProjects.single.projectId, project.id);
    expect(repository.promotedProjects.single.name, 'Portrait edit');
    expect(repository.promotedProjects.single.state.edits.single.value, 30);

    final savedPreviewPath = repository.updatedPreviewPaths.last;

    await vm.resetEdits();

    expect(repository.updatedPreviewPaths.last, isNot(savedPreviewPath));
    expect(await File(repository.updatedPreviewPaths.last).exists(), isTrue);
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
      id: 1,
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

    final loaded = await vm.loadProject(1);

    expect(loaded, isTrue);
    expect(vm.currentProject?.id, 1);
    expect(vm.currentProject?.lastOpenedAt, openedAt);
    expect(vm.originalImagePath, sourceFile.path);
    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(repository.openedProjects.single.projectId, 1);
    expect(repository.openedProjects.single.openedAt, openedAt);
  });

  test('versions clone and preserve independent undo and redo stacks', () async {
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
    final version1 = vm.activeVersion;

    expect(version1, isNotNull);
    expect(version1!.name, 'Version 1');

    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 30));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 30));
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.contrast, value: 10));
    await vm.applyEdit(Edit(type: OperationType.contrast, value: 10));
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.exposure, value: 5));
    await vm.applyEdit(Edit(type: OperationType.exposure, value: 5));

    final v1Undo = await vm.undo();

    expect(v1Undo?.label, 'Exposure +5');
    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(vm.getEditValue(OperationType.contrast), 10);
    expect(vm.getEditValue(OperationType.exposure), 0);
    expect(vm.canRedo, isTrue);

    final version2 = await vm.saveCurrentVersion(name: 'Client option');

    expect(version2, isNotNull);
    expect(version2!.projectId, 1);
    expect(version2.name, 'Client option');
    expect(version2.parentVersionId, version1.id);
    expect(vm.activeVersion?.id, version2.id);
    expect(vm.canRedo, isTrue);

    final renamedVersion2 = await vm.renameVersion(
      version2.id,
      'Client option with a name longer than thirty two characters',
    );

    expect(renamedVersion2, isNotNull);
    expect(renamedVersion2!.name.length, EditorViewModel.versionNameMaxLength);
    expect(vm.activeVersion?.name, renamedVersion2.name);

    final v2Redo = await vm.redo();

    expect(v2Redo?.label, 'Exposure +5');
    expect(vm.getEditValue(OperationType.exposure), 5);

    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.saturation, value: 20));
    await vm.applyEdit(Edit(type: OperationType.saturation, value: 20));
    final version2PreviewPath = repository.updatedPreviewPaths.last;

    final switchToVersion1 = await vm.switchToVersion(version1.id);

    expect(switchToVersion1?.label, 'Version 1');
    expect(repository.updatedPreviewPaths.last, isNot(version2PreviewPath));
    expect(await File(repository.updatedPreviewPaths.last).exists(), isTrue);
    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(vm.getEditValue(OperationType.contrast), 10);
    expect(vm.getEditValue(OperationType.exposure), 0);
    expect(vm.getEditValue(OperationType.saturation), 0);
    expect(vm.canRedo, isTrue);

    final v1Redo = await vm.redo();

    expect(v1Redo?.label, 'Exposure +5');
    expect(vm.getEditValue(OperationType.exposure), 5);
    expect(vm.getEditValue(OperationType.saturation), 0);
    final version1PreviewPath = repository.updatedPreviewPaths.last;

    final switchToVersion2 = await vm.switchToVersion(version2.id);

    expect(switchToVersion2?.label, renamedVersion2.name);
    expect(repository.updatedPreviewPaths.last, isNot(version1PreviewPath));
    expect(await File(repository.updatedPreviewPaths.last).exists(), isTrue);
    expect(vm.getEditValue(OperationType.exposure), 5);
    expect(vm.getEditValue(OperationType.saturation), 20);

    final v2Undo = await vm.undo();

    expect(v2Undo?.label, 'Saturation +20');
    expect(vm.getEditValue(OperationType.exposure), 5);
    expect(vm.getEditValue(OperationType.saturation), 0);

    final deletedVersion2 = await vm.deleteVersion(version2.id);

    expect(deletedVersion2, isTrue);
    expect(vm.versions, hasLength(1));
    expect(vm.activeVersion?.id, version1.id);
    expect(repository.savedVersions.any((version) => version.id == version2.id),
        isFalse);

    final deletedLastVersion = await vm.deleteVersion(version1.id);

    expect(deletedLastVersion, isFalse);
    expect(vm.versions, hasLength(1));
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

  final int projectId;
  final EditorEditState state;
  final DateTime updatedAt;
}

class _OpenedProject {
  const _OpenedProject({
    required this.projectId,
    required this.openedAt,
  });

  final int projectId;
  final DateTime openedAt;
}

class _PromotedProject {
  const _PromotedProject({
    required this.projectId,
    required this.name,
    required this.state,
    required this.updatedAt,
  });

  final int projectId;
  final String name;
  final EditorEditState state;
  final DateTime updatedAt;
}

class _FakeEditorProjectRepository implements EditorProjectRepository {
  final List<EditorProject> savedProjects = [];
  final List<_SavedState> savedStates = [];
  final List<_OpenedProject> openedProjects = [];
  final List<_PromotedProject> promotedProjects = [];
  final List<String> updatedPreviewPaths = [];
  final List<EditorVersion> savedVersions = [];

  @override
  Future<void> deleteProject(int id) async {}

  @override
  Future<void> deleteVersion(String id) async {
    savedVersions.removeWhere((version) => version.id == id);
  }

  @override
  Future<EditorProject?> loadProject(int id) async {
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
  Future<EditorVersion?> loadVersion(String id) async {
    return savedVersions.where((version) => version.id == id).firstOrNull;
  }

  @override
  Future<List<EditorVersion>> loadVersions(int projectId) async {
    return savedVersions
        .where((version) => version.projectId == projectId)
        .toList();
  }

  @override
  Future<void> markProjectOpened({
    required int projectId,
    required DateTime openedAt,
  }) async {
    openedProjects.add(_OpenedProject(
      projectId: projectId,
      openedAt: openedAt,
    ));
  }

  @override
  Future<void> promoteDraftToSaved({
    required int projectId,
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
    required int projectId,
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
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  }) async {
    updatedPreviewPaths.add(previewImagePath);
    final index = savedProjects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    savedProjects[index] = savedProjects[index].copyWith(
      previewImagePath: previewImagePath,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> setActiveVersion({
    required int projectId,
    required String? versionId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    final index = savedProjects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    savedProjects[index] = savedProjects[index].copyWith(
      activeVersionId: versionId,
      currentState: state,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<EditorProject> saveProject(EditorProject project) async {
    final savedProject = project.id > 0
        ? project
        : project.copyWith(id: savedProjects.length + 1);
    final index =
        savedProjects.indexWhere((existing) => existing.id == savedProject.id);
    if (index == -1) {
      savedProjects.add(savedProject);
    } else {
      savedProjects[index] = savedProject;
    }
    return savedProject;
  }

  @override
  Future<void> saveVersion(EditorVersion version) async {
    final index =
        savedVersions.indexWhere((existing) => existing.id == version.id);
    if (index == -1) {
      savedVersions.add(version);
    } else {
      savedVersions[index] = version;
    }
  }
}
