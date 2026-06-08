import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/ai_provider.dart';
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/ai_profile_settings.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/model/export_settings.dart';
import 'package:licenta/model/rgba_image_frame.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/repositories/preset_repository.dart';
import 'package:licenta/services/ai_profiles_api_key_storage.dart';
import 'package:licenta/services/ai_profiles_storage.dart';
import 'package:licenta/services/edit_pipeline_worker.dart';
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
    expect(project.name, unnamedDraftProjectName);
    expect(project.status, EditorProjectStatus.draft);
    expect(project.originalImagePath, isNot(sourceFile.path));
    expect(project.originalImagePath, vm.originalImagePath);
    expect(await File(project.originalImagePath).exists(), isTrue);
    expect(vm.exportSettings.format, ImageFormat.png);
    expect(project.originalWidth, 16);
    expect(project.originalHeight, 16);
    expect(project.previewWidth, 16);
    expect(project.previewHeight, 16);
    expect(vm.messages, isEmpty);
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
    expect(vm.canOpenProjectSettings, isTrue);
    expect(vm.defaultProjectName, 'Project 1');

    await repository.renameProject(
      projectId: project.id,
      name: 'Renamed draft',
      updatedAt: DateTime.utc(2026, 5, 16, 13),
    );
    final refreshedMetadata = await vm.refreshCurrentProjectMetadata();

    expect(refreshedMetadata, isTrue);
    expect(vm.currentProject?.name, 'Renamed draft');
    expect(vm.defaultProjectName, 'Renamed draft');

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
    repository.aiMessagesByProject[1] = [
      ChatMessage(
        text: 'Make it warmer',
        type: MessageType.user,
        timestamp: savedAt,
      ),
      ChatMessage(
        text: 'Added warmth.',
        type: MessageType.ai,
        timestamp: savedAt.add(const Duration(seconds: 1)),
      ),
    ];
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
    expect(vm.messages.map((message) => message.text), [
      'Make it warmer',
      'Added warmth.',
    ]);
    final activeVersionId = vm.activeVersion!.id;
    expect(repository.migratedAiMessageVersionIds, [activeVersionId]);
    expect(repository.aiMessagesByProject[1], isNull);
    expect(repository.aiMessagesByVersion[activeVersionId]!.map((message) => message.text), [
      'Make it warmer',
      'Added warmth.',
    ]);
    expect(repository.openedProjects.single.projectId, 1);
    expect(repository.openedProjects.single.openedAt, openedAt);

    await vm.clearChat();

    expect(vm.messages, isEmpty);
    expect(repository.clearedAiMessageVersionIds, [activeVersionId]);
    expect(repository.aiMessagesByVersion[activeVersionId], isNull);

    await vm.sendMessage('Try a softer look');

    final persistedMessages = repository.aiMessagesByVersion[activeVersionId]!;
    expect(persistedMessages.map((message) => message.type), [
      MessageType.user,
      MessageType.error,
    ]);
    expect(persistedMessages.first.text, 'Try a softer look');
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

    await vm.sendMessage('Remember this branch');

    expect(repository.aiMessagesByVersion[version1.id]!.map((message) => message.type), [
      MessageType.user,
      MessageType.error,
    ]);

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
    expect(repository.aiMessagesByVersion[version2.id]!.map((message) => message.text), [
      'Remember this branch',
      'API key not configured. Set your Gemini API key.',
    ]);

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
    await vm.sendMessage('Version 2 note');
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
    expect(vm.messages.map((message) => message.text), [
      'Remember this branch',
      'API key not configured. Set your Gemini API key.',
    ]);

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
    expect(vm.messages.map((message) => message.text), [
      'Remember this branch',
      'API key not configured. Set your Gemini API key.',
      'Version 2 note',
      'API key not configured. Set your Gemini API key.',
    ]);

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

  test('AI reference image is stored per version and cleared with chat',
      () async {
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
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.importImageAsProject(sourceFile.path);
    final version1 = vm.activeVersion!;

    final attached = await vm.attachAiReferenceImage(sourceFile.path);

    expect(attached, isTrue);
    expect(vm.hasAiReferenceImage, isTrue);
    final version1ReferencePath = vm.aiReferenceImagePath;
    expect(version1ReferencePath, isNotNull);
    expect(await File(version1ReferencePath!).exists(), isTrue);
    expect(
      repository.savedVersions
          .where((version) => version.id == version1.id)
          .single
          .aiReferenceImagePath,
      version1ReferencePath,
    );

    final version2 = await vm.saveCurrentVersion(name: 'Reference branch');

    expect(version2, isNotNull);
    expect(version2!.aiReferenceImagePath, isNotNull);
    expect(version2.aiReferenceImagePath, isNot(version1ReferencePath));
    expect(await File(version2.aiReferenceImagePath!).exists(), isTrue);
    expect(vm.aiReferenceImagePath, version2.aiReferenceImagePath);

    await vm.clearChat();

    expect(vm.hasAiReferenceImage, isFalse);
    expect(await File(version2.aiReferenceImagePath!).exists(), isFalse);
    expect(await File(version1ReferencePath).exists(), isTrue);
    expect(
      repository.savedVersions
          .where((version) => version.id == version2.id)
          .single
          .aiReferenceImagePath,
      isNull,
    );
  });

  test('saves compact presets and generates the first available default name',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final presetRepository = _FakePresetRepository()
      ..presets.add(_preset(
        id: 1,
        name: 'Preset 1',
        state: _presetState(OperationType.warmth, 8),
      ));
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      presetRepository: presetRepository,
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await sourceFile.parent.exists()) {
        await sourceFile.parent.delete(recursive: true);
      }
    });

    await vm.loadImageFromPath(sourceFile.path);

    expect(vm.canSavePreset, isFalse);
    expect(
      () => vm.saveCurrentPreset('Empty'),
      throwsA(isA<PresetValidationException>()),
    );
    expect(await vm.defaultPresetName(), 'Preset 2');

    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 25));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 25));
    final saved = await vm.saveCurrentPreset('Portrait');

    expect(saved.name, 'Portrait');
    expect(saved.state.edits.single.type, OperationType.brightness);
    expect(saved.state.edits.single.value, 25);
  });

  test('preset merge and replace are atomic history actions and persist preview',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final tempDir = sourceFile.parent;
    final projectRepository = _FakeEditorProjectRepository();
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      projectRepository: projectRepository,
      presetRepository: _FakePresetRepository(),
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
      now: () => DateTime.utc(2026, 6, 1, 12),
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.importImageAsProject(sourceFile.path);
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 15));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 15));
    final previewBeforePreset = projectRepository.updatedPreviewPaths.last;
    final contrastPreset = _preset(
      id: 1,
      name: 'Contrast lift',
      state: _presetState(OperationType.contrast, 20),
    );

    final mergeResult = await vm.applyPreset(
      contrastPreset,
      PresetApplyMode.merge,
    );

    expect(mergeResult?.label, 'Merged preset Contrast lift');
    expect(vm.getEditValue(OperationType.brightness), 15);
    expect(vm.getEditValue(OperationType.contrast), 20);
    expect(projectRepository.updatedPreviewPaths.last, isNot(previewBeforePreset));
    expect(projectRepository.savedVersions.single.state.edits, hasLength(2));

    final undoMerge = await vm.undo();
    expect(undoMerge?.label, 'Merged preset Contrast lift');
    expect(vm.getEditValue(OperationType.brightness), 15);
    expect(vm.getEditValue(OperationType.contrast), 0);

    final redoMerge = await vm.redo();
    expect(redoMerge?.label, 'Merged preset Contrast lift');
    expect(vm.getEditValue(OperationType.contrast), 20);

    final blurPreset = _preset(
      id: 2,
      name: 'Soft focus',
      state: _presetState(OperationType.blur, 6),
    );
    final replaceResult = await vm.applyPreset(
      blurPreset,
      PresetApplyMode.replace,
    );

    expect(replaceResult?.label, 'Replaced preset Soft focus');
    expect(vm.getEditValue(OperationType.brightness), 0);
    expect(vm.getEditValue(OperationType.contrast), 0);
    expect(vm.getEditValue(OperationType.blur), 6);
    expect(
      await vm.applyPreset(blurPreset, PresetApplyMode.replace),
      isNull,
    );
    expect((await vm.undo())?.label, 'Replaced preset Soft focus');
    expect(vm.getEditValue(OperationType.brightness), 15);
    expect(vm.getEditValue(OperationType.contrast), 20);
  });

  test('active AI profile can be switched from the editor', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
    );
    addTearDown(vm.dispose);

    await vm.updateAiSettings(
      const AiProfilesUpdate(
        profiles: [
          AiProfileSettings(),
          AiProfileSettings(
            id: 'openai-profile',
            profileName: 'OpenAI profile',
            providerId: AiProfileSettings.openAiProviderId,
            model: 'gpt-5.4-mini',
          ),
        ],
        activeProfileId: AiProfileSettings.defaultProfileId,
      ),
      const {},
    );

    expect(vm.activeAiProfileId, AiProfileSettings.defaultProfileId);
    expect(vm.selectedProvider, AiProfileSettings.geminiProviderId);
    expect(
      vm.availableProviders,
      contains(AiProfileSettings.claudeProviderId),
    );
    expect(
      vm.modelsForProvider(AiProfileSettings.claudeProviderId),
      contains('claude-haiku-4-5'),
    );

    await vm.setActiveAiProfile('openai-profile');

    expect(vm.activeAiProfileId, 'openai-profile');
    expect(vm.aiProfileSettings.profileName, 'OpenAI profile');
    expect(vm.selectedProvider, AiProfileSettings.openAiProviderId);
    expect(vm.selectedModel, 'gpt-5.4-mini');
  });

  test('AI no-edit response persists chat without processing image', () async {
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
    final worker = _TrackingEditPipelineWorker();
    final provider = _QueueAiProvider([
      '{"message":"That request does not describe a supported photo edit."}',
    ]);
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      editPipelineWorker: worker,
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
      providerFactories: {
        AiProfileSettings.geminiProviderId: (_) => provider,
      },
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.importImageAsProject(sourceFile.path);
    final activeVersionId = vm.activeVersion!.id;
    final processCount = worker.processCount;
    final previewCount = repository.updatedPreviewPaths.length;

    await vm.sendMessage('What is the capital of France?');

    expect(provider.callCount, 1);
    expect(vm.messages.map((message) => message.type), [
      MessageType.user,
      MessageType.ai,
    ]);
    expect(
      vm.messages.last.text,
      'That request does not describe a supported photo edit.',
    );
    expect(vm.hasPendingEdits, isFalse);
    expect(vm.canUndo, isFalse);
    expect(vm.getEditValue(OperationType.brightness), 0);
    expect(worker.processCount, processCount);
    expect(repository.updatedPreviewPaths, hasLength(previewCount));
    expect(
      repository.aiMessagesByVersion[activeVersionId]
          ?.map((message) => message.type),
      [MessageType.user, MessageType.ai],
    );
  });

  test('effective AI no-op does not process or add history', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final worker = _TrackingEditPipelineWorker();
    final provider = _QueueAiProvider([
      '{"message":"The brightness already matches that request.",'
          '"edits":[{"type":"brightness","value":20}]}',
    ]);
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      editPipelineWorker: worker,
      providerFactories: {
        AiProfileSettings.geminiProviderId: (_) => provider,
      },
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      final tempDir = sourceFile.parent;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.loadImageFromPath(sourceFile.path);
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 20));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 20));
    final processCount = worker.processCount;

    await vm.sendMessage('Keep the brightness at twenty.');

    expect(vm.hasPendingEdits, isFalse);
    expect(vm.getEditValue(OperationType.brightness), 20);
    expect(worker.processCount, processCount);
    expect((await vm.undo())?.label, 'Brightness +20');
    expect(vm.getEditValue(OperationType.brightness), 0);
    expect(vm.canUndo, isFalse);
  });

  test('invalid AI response retries before accepting no-edit reply', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final provider = _QueueAiProvider([
      'not json',
      '{"message":"I could not identify a supported photo edit."}',
    ]);
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      providerFactories: {
        AiProfileSettings.geminiProviderId: (_) => provider,
      },
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      final tempDir = sourceFile.parent;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.loadImageFromPath(sourceFile.path);
    await vm.sendMessage('asdfgh');

    expect(provider.callCount, 2);
    expect(provider.prompts.last, contains('Invalid JSON'));
    expect(vm.messages.map((message) => message.type), [
      MessageType.user,
      MessageType.ai,
    ]);
    expect(vm.hasPendingEdits, isFalse);
  });

  test('valid AI edit still creates one pending history action', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    final worker = _TrackingEditPipelineWorker();
    final provider = _QueueAiProvider([
      '{"message":"Brightened the image.",'
          '"edits":[{"type":"brightness","value":15}]}',
    ]);
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      editPipelineWorker: worker,
      providerFactories: {
        AiProfileSettings.geminiProviderId: (_) => provider,
      },
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      final tempDir = sourceFile.parent;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.loadImageFromPath(sourceFile.path);
    await vm.sendMessage('Make it brighter.');

    expect(worker.processCount, 1);
    expect(vm.hasPendingEdits, isTrue);
    expect(vm.getEditValue(OperationType.brightness), 15);
    expect(vm.canUndo, isFalse);

    vm.applyPendingEdits();

    expect(vm.hasPendingEdits, isFalse);
    expect(vm.canUndo, isTrue);
    expect((await vm.undo())?.label, 'AI edit');
    expect(vm.getEditValue(OperationType.brightness), 0);
  });

  test('versions inherit and restore independent AI profiles', () async {
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
    final storage = _FakeAiProfilesStorage(
      persisted: const PersistedAiProfiles(
        profiles: [
          AiProfileSettings(),
          AiProfileSettings(
            id: 'openai-profile',
            profileName: 'OpenAI profile',
            providerId: AiProfileSettings.openAiProviderId,
            model: 'gpt-5.4-mini',
          ),
        ],
        activeProfileId: 'openai-profile',
      ),
    );
    final vm = EditorViewModel(
      aiProfilesStorage: storage,
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
    final version1 = vm.activeVersion!;

    expect(version1.aiProfileId, 'openai-profile');
    expect(vm.activeAiProfileId, 'openai-profile');

    final version2 = await vm.saveCurrentVersion(name: 'Gemini branch');

    expect(version2, isNotNull);
    expect(version2!.aiProfileId, 'openai-profile');

    await vm.setActiveAiProfile(AiProfileSettings.defaultProfileId);

    expect(vm.activeVersion?.aiProfileId, AiProfileSettings.defaultProfileId);
    expect(storage.persisted?.activeProfileId,
        AiProfileSettings.defaultProfileId);
    final globalSaveCount = storage.saveCount;

    await vm.switchToVersion(version1.id);

    expect(vm.activeAiProfileId, 'openai-profile');
    expect(vm.selectedProvider, AiProfileSettings.openAiProviderId);
    expect(storage.saveCount, globalSaveCount);
    expect(storage.persisted?.activeProfileId,
        AiProfileSettings.defaultProfileId);

    final restoredVm = EditorViewModel(
      aiProfilesStorage: storage,
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    addTearDown(restoredVm.dispose);

    expect(await restoredVm.loadProject(1), isTrue);
    expect(restoredVm.activeVersion?.id, version1.id);
    expect(restoredVm.activeAiProfileId, 'openai-profile');
    expect(storage.persisted?.activeProfileId,
        AiProfileSettings.defaultProfileId);
  });

  test('missing version AI profile falls back and is persisted', () async {
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
    final storage = _FakeAiProfilesStorage(
      persisted: const PersistedAiProfiles(
        profiles: [
          AiProfileSettings(),
          AiProfileSettings(
            id: 'openai-profile',
            profileName: 'OpenAI profile',
            providerId: AiProfileSettings.openAiProviderId,
            model: 'gpt-5.4-mini',
          ),
        ],
        activeProfileId: AiProfileSettings.defaultProfileId,
      ),
    );
    final vm = EditorViewModel(
      aiProfilesStorage: storage,
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    addTearDown(vm.dispose);
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await vm.importImageAsProject(sourceFile.path);
    final version1 = vm.activeVersion!;
    await vm.setActiveAiProfile('openai-profile');
    final version2 = await vm.saveCurrentVersion(name: 'Current branch');

    expect(version1.id, isNot(version2?.id));
    expect(version2?.aiProfileId, 'openai-profile');
    expect(
      repository.savedVersions
          .where((version) => version.id == version1.id)
          .single
          .aiProfileId,
      'openai-profile',
    );

    await vm.updateAiSettings(
      const AiProfilesUpdate(
        profiles: [AiProfileSettings()],
        activeProfileId: AiProfileSettings.defaultProfileId,
      ),
      const {},
    );

    expect(vm.activeVersion?.aiProfileId,
        AiProfileSettings.defaultProfileId);
    expect(storage.persisted?.activeProfileId,
        AiProfileSettings.defaultProfileId);

    await vm.switchToVersion(version1.id);

    expect(vm.activeAiProfileId, AiProfileSettings.defaultProfileId);
    expect(vm.activeVersion?.aiProfileId,
        AiProfileSettings.defaultProfileId);
    expect(
      repository.savedVersions
          .where((version) => version.id == version1.id)
          .single
          .aiProfileId,
      AiProfileSettings.defaultProfileId,
    );
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
  _FakeAiProfilesStorage({this.persisted});

  PersistedAiProfiles? persisted;
  int saveCount = 0;

  @override
  Future<PersistedAiProfiles?> load() async => persisted;

  @override
  Future<void> save({
    required List<AiProfileSettings> profiles,
    required String activeProfileId,
  }) async {
    saveCount++;
    persisted = PersistedAiProfiles(
      profiles: List<AiProfileSettings>.from(profiles),
      activeProfileId: activeProfileId,
    );
  }
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

class _QueueAiProvider implements AiProvider {
  _QueueAiProvider(this.responses);

  final List<String> responses;
  final List<String> prompts = [];

  int get callCount => prompts.length;

  @override
  String get name => 'Test AI';

  @override
  List<String> get models => const [AiProfileSettings.defaultModel];

  @override
  String get defaultModel => AiProfileSettings.defaultModel;

  @override
  Future<String> sendPrompt(
    String userMessage, {
    Uint8List? imageBytes,
    Uint8List? referenceImageBytes,
    String? model,
    List<ChatMessage> history = const [],
    String? currentStateJson,
  }) async {
    prompts.add(userMessage);
    final responseIndex = prompts.length - 1;
    if (responseIndex >= responses.length) {
      throw StateError('No queued AI response');
    }
    return responses[responseIndex];
  }
}

class _TrackingEditPipelineWorker extends EditPipelineWorker {
  RgbaImageFrame? _originalFrame;
  int processCount = 0;

  @override
  Future<void> loadOriginalFrame(RgbaImageFrame frame) async {
    _originalFrame = frame;
  }

  @override
  Future<RgbaImageFrame> process({
    required List<Edit> edits,
    required List<ColorEdit> colorEdits,
    required List<ColorGradingEdit> colorGradingEdits,
  }) async {
    processCount++;
    return _originalFrame!;
  }

  @override
  void dispose() {}
}

class _FakePresetRepository implements PresetRepository {
  final List<EditorPreset> presets = [];

  @override
  Future<EditorPreset> createPreset({
    required String name,
    required EditorEditState state,
    required DateTime createdAt,
  }) async {
    final compact = state.activeOnly();
    if (compact.isEmpty) {
      throw const PresetValidationException(
        'Cannot save a preset without edits.',
      );
    }
    final preset = EditorPreset(
      id: presets.length + 1,
      name: name.trim(),
      state: compact,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    presets.add(preset);
    return preset;
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
    final index = presets.indexWhere((preset) => preset.id == id);
    final current = presets[index];
    final renamed = EditorPreset(
      id: current.id,
      name: name.trim(),
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
  required EditorEditState state,
}) {
  final createdAt = DateTime.utc(2026, 6, 1);
  return EditorPreset(
    id: id,
    name: name,
    state: state,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

EditorEditState _presetState(OperationType type, double value) {
  return EditorEditState(
    edits: [Edit(type: type, value: value)],
    colorEdits: const [],
    colorGradingEdits: const [],
  );
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
  final Map<int, List<ChatMessage>> aiMessagesByProject = {};
  final Map<String, List<ChatMessage>> aiMessagesByVersion = {};
  final List<int> clearedAiMessageProjectIds = [];
  final List<String> clearedAiMessageVersionIds = [];
  final List<String> migratedAiMessageVersionIds = [];

  @override
  Future<void> deleteProject(int id) async {}

  @override
  Future<void> deleteVersion(String id) async {
    savedVersions.removeWhere((version) => version.id == id);
  }

  @override
  Future<List<ChatMessage>> loadAiMessagesForProject(int projectId) async {
    return List.of(aiMessagesByProject[projectId] ?? const []);
  }

  @override
  Future<void> saveAiMessageForProject({
    required int projectId,
    required ChatMessage message,
  }) async {
    aiMessagesByProject.putIfAbsent(projectId, () => []).add(message);
  }

  @override
  Future<void> clearAiMessagesForProject(int projectId) async {
    clearedAiMessageProjectIds.add(projectId);
    aiMessagesByProject.remove(projectId);
  }

  @override
  Future<List<ChatMessage>> loadAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {
    return List.of(aiMessagesByVersion[versionId] ?? const []);
  }

  @override
  Future<void> saveAiMessageForVersion({
    required int projectId,
    required String versionId,
    required ChatMessage message,
  }) async {
    aiMessagesByVersion.putIfAbsent(versionId, () => []).add(message);
  }

  @override
  Future<void> cloneAiMessagesForVersion({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {
    aiMessagesByVersion[targetVersionId] =
        List.of(aiMessagesByVersion[sourceVersionId] ?? const []);
  }

  @override
  Future<void> moveProjectAiMessagesToVersion({
    required int projectId,
    required String versionId,
  }) async {
    final messages = aiMessagesByProject.remove(projectId);
    if (messages == null) return;
    migratedAiMessageVersionIds.add(versionId);
    aiMessagesByVersion[versionId] = List.of(messages);
  }

  @override
  Future<void> clearAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {
    clearedAiMessageVersionIds.add(versionId);
    aiMessagesByVersion.remove(versionId);
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
  Future<void> renameProject({
    required int projectId,
    required String name,
    required DateTime updatedAt,
  }) async {
    final index = savedProjects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    savedProjects[index] = savedProjects[index].copyWith(
      name: name,
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
