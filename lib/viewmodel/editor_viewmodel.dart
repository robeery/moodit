import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../model/ai_exception.dart';
import '../model/ai_profile_settings.dart';
import '../model/edit.dart';
import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';
import '../model/editor_edit_source.dart';
import '../model/editor_edit_state.dart';
import '../model/editor_history_entry.dart';
import '../model/editor_preset.dart';
import '../model/editor_project.dart';
import '../model/editor_version.dart';
import '../model/photo_editing_image.dart';
import '../model/rgba_image_frame.dart';
import '../model/history_action_result.dart';
import '../domain/edit_pipeline/image_frame_codec.dart';
import '../domain/parse_edits_json.dart';
import '../model/chat_message.dart';
import '../model/export_settings.dart';
import '../domain/ai_provider.dart';
import '../services/ai_profiles_api_key_storage.dart';
import '../services/ai_profiles_storage.dart';
import '../services/edit_pipeline_worker.dart';
import '../services/editor_history.dart';
import '../services/export_service.dart';
import '../services/gemini_provider.dart';
import '../services/openai_provider.dart';
import '../services/preview_image_decoder.dart';
import '../services/project_file_store.dart';
import '../repositories/editor_project_repository.dart';
import '../repositories/editor_project_repository_factory.dart';
import '../repositories/preset_repository.dart';
import '../repositories/preset_repository_factory.dart';

enum EditorMode { basic, selectiveColor, colorGrading, askAi }

class EditorViewModel extends ChangeNotifier {
  static const String _projectHistoryKey = '__project__';
  static const int versionNameMaxLength = 32;
  static const int _projectPreviewMaxDimension = 256;

  final Map<String, AiProvider Function(String? apiKey)> _providerFactories = {
    AiProfileSettings.geminiProviderId: (apiKey) => GeminiProvider(apiKey: apiKey),
    AiProfileSettings.openAiProviderId: (apiKey) => OpenAiProvider(apiKey: apiKey),
  };

  PhotoEditingImage? _photoEditingImage;
  RgbaImageFrame? _originalFrame;
  RgbaImageFrame? _processedFrame;
  ui.Image? _originalPreviewImage;
  ui.Image? _processedPreviewImage;
  bool _isProcessing = false;
  int? _lastBenchmarkMs; // temporary benchmark
  double? _exportProgress;
  bool _isWaitingForAi = false;
  bool _isOnline = true;
  bool _isAiReady = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  OperationType _selectedOperation = OperationType.exposure;
  ColorRange _selectedColorRange = ColorRange.red;
  EditorMode _editorMode = EditorMode.basic;
  ColorGradingZone _selectedGradingZone = ColorGradingZone.shadows;
  final List<ChatMessage> _messages = [];
  late AiProvider _aiProvider;
  final AiProfilesApiKeyStorage _aiProfilesApiKeyStorage;
  final AiProfilesStorage _aiProfilesStorage;
  final EditPipelineWorker _editPipelineWorker;
  final PreviewImageDecoder _previewImageDecoder;
  EditorProjectRepository? _projectRepository;
  PresetRepository? _presetRepository;
  late final ProjectFileStore _projectFileStore;
  final DateTime Function() _now;
  Future<void> Function()? _disposeOwnedProjectRepository;
  Future<void> Function()? _disposeOwnedPresetRepository;
  final ExportService _exportService = ExportService();
  ExportSettings _exportSettings = const ExportSettings();
  EditorProject? _currentProject;
  List<EditorVersion> _versions = [];
  String? _activeVersionId;
  ParsedEdits? _pendingEdits;
  EditorHistoryEntry? _pendingAiHistoryEntry;
  String? _pendingAiProviderId;
  RgbaImageFrame? _snapshotProcessedFrame;
  final Map<String, EditorHistory> _versionHistories = {};
  EditorHistory _history = EditorHistory();
  EditorEditState? _manualEditBeforeState;
  List<AiProfileSettings> _aiProfiles;
  String _activeAiProfileId;
  Map<String, String> _apiKeysByProfileId = {};
  int _projectPreviewRevision = 0;

  EditorViewModel({
    AiProfilesStorage? aiProfilesStorage,
    AiProfilesApiKeyStorage? aiProfilesApiKeyStorage,
    EditPipelineWorker? editPipelineWorker,
    PreviewImageDecoder? previewImageDecoder,
    EditorProjectRepository? projectRepository,
    PresetRepository? presetRepository,
    ProjectFileStore? projectFileStore,
    DateTime Function()? now,
  })
      : _aiProfiles = [const AiProfileSettings()],
        _activeAiProfileId = AiProfileSettings.defaultProfileId,
        _aiProfilesApiKeyStorage =
            aiProfilesApiKeyStorage ?? const AiProfilesApiKeyStorage(),
        _aiProfilesStorage = aiProfilesStorage ?? AiProfilesStorage(),
        _editPipelineWorker = editPipelineWorker ?? EditPipelineWorker(),
        _previewImageDecoder =
            previewImageDecoder ?? const PreviewImageDecoder(),
        _now = now ?? DateTime.now {
    _projectRepository = projectRepository;
    _presetRepository = presetRepository;
    _projectFileStore = projectFileStore ?? ProjectFileStore();

    _initializeAiProvider();
    unawaited(_loadPersistedAiProfiles());

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  Future<void> _loadPersistedAiProfiles() async {
    try {
      final persisted = await _aiProfilesStorage.load();
      if (persisted != null) {
        _applyAiProfilesUpdate(
          AiProfilesUpdate(
            profiles: persisted.profiles,
            activeProfileId: persisted.activeProfileId,
          ),
          persistAfterApply: false,
        );
      }
      await _loadApiKeysForCurrentProfiles();
    } finally {
      _isAiReady = true;
      notifyListeners();
    }
  }

  Future<void> _persistAiProfiles() async {
    try {
      await _aiProfilesStorage.save(
        profiles: _aiProfiles,
        activeProfileId: _activeAiProfileId,
      );
    } catch (_) {
      // Persistence is best-effort; runtime state still stays valid in memory
    }
  }

  Future<void> _loadApiKeysForCurrentProfiles() async {
    try {
      _apiKeysByProfileId = await _aiProfilesApiKeyStorage.readMany(
        _aiProfiles.map((p) => p.id),
      );
      _initializeAiProvider();
    } catch (_) {
      // Secure storage read failures should not block app usage
    }
  }

  Future<void> _persistApiKeys() async {
    try {
      await _aiProfilesApiKeyStorage.saveForProfiles(
        apiKeysByProfileId: _apiKeysByProfileId,
        validProfileIds: _aiProfiles.map((p) => p.id).toSet(),
      );
    } catch (_) {
      // Secure storage writes are best-effort
    }
  }

  Map<String, String> _normalizeApiKeys(
    Map<String, String> apiKeysByProfileId,
    Iterable<String> validProfileIds,
  ) {
    final valid = validProfileIds.toSet();
    final normalized = <String, String>{};
    for (final entry in apiKeysByProfileId.entries) {
      final profileId = entry.key.trim();
      if (profileId.isEmpty || !valid.contains(profileId)) continue;
      final apiKey = entry.value.trim();
      if (apiKey.isEmpty) continue;
      normalized[profileId] = apiKey;
    }
    return normalized;
  }

  String _resolveProviderId(String providerId) {
    if (_providerFactories.containsKey(providerId)) {
      return providerId;
    }
    return _providerFactories.keys.first;
  }

  int _activeProfileIndex() {
    final index = _aiProfiles.indexWhere((p) => p.id == _activeAiProfileId);
    return index >= 0 ? index : 0;
  }

  AiProfileSettings _activeProfile() => _aiProfiles[_activeProfileIndex()];

  void _replaceActiveProfile(AiProfileSettings profile) {
    final index = _activeProfileIndex();
    _aiProfiles[index] = profile;
  }

  AiProfilesUpdate _normalizeAiProfilesUpdate(AiProfilesUpdate update) {
    final incomingProfiles = update.profiles;
    if (incomingProfiles.isEmpty) {
      return const AiProfilesUpdate(
        profiles: [AiProfileSettings()],
        activeProfileId: AiProfileSettings.defaultProfileId,
      );
    }

    final normalized = <AiProfileSettings>[];
    final seenIds = <String>{};

    for (final profile in incomingProfiles) {
      final rawId = profile.id.trim();
      final id = rawId.isEmpty || seenIds.contains(rawId)
          ? '${DateTime.now().microsecondsSinceEpoch}_${normalized.length}'
          : rawId;
      seenIds.add(id);

      final safeName = profile.profileName.trim().isEmpty
          ? AiProfileSettings.defaultProfileName
          : profile.profileName.trim();
      final safeHistory = profile.historyWindowSize
          .clamp(
            AiProfileSettings.minHistoryWindowSize,
            AiProfileSettings.maxHistoryWindowSize,
          )
          .toInt();

      normalized.add(profile.copyWith(
        id: id,
        profileName: safeName,
        historyWindowSize: safeHistory,
      ));
    }

    final activeProfileId = normalized.any((p) => p.id == update.activeProfileId)
        ? update.activeProfileId
        : normalized.first.id;

    return AiProfilesUpdate(
      profiles: normalized,
      activeProfileId: activeProfileId,
    );
  }

  void _applyAiProfilesUpdate(
    AiProfilesUpdate update, {
    bool persistAfterApply = true,
  }) {
    final normalizedUpdate = _normalizeAiProfilesUpdate(update);
    _aiProfiles = List<AiProfileSettings>.from(normalizedUpdate.profiles);
    _activeAiProfileId = normalizedUpdate.activeProfileId;

    if (persistAfterApply) {
      unawaited(_persistAiProfiles());
    }
  }

  void _initializeAiProvider() {
    final active = _activeProfile();
    final resolvedProviderId = _resolveProviderId(active.providerId);
    final providerFactory = _providerFactories[resolvedProviderId]!;
    final apiKey = _apiKeysByProfileId[active.id];
    _aiProvider = providerFactory(apiKey);

    if (!_aiProvider.models.contains(active.model)) {
      _replaceActiveProfile(active.copyWith(
        providerId: resolvedProviderId,
        model: _aiProvider.defaultModel,
      ));
      return;
    }

    if (resolvedProviderId != active.providerId) {
      _replaceActiveProfile(active.copyWith(
        providerId: resolvedProviderId,
      ));
    }
  }

  bool get hasImage => _photoEditingImage != null;
  bool get hasPreviewImages =>
      _processedPreviewImage != null && _originalPreviewImage != null;
  PhotoEditingImage? getModel() => _photoEditingImage;
  EditorProject? get currentProject => _currentProject;
  List<EditorVersion> get versions => List.unmodifiable(_versions);
  EditorVersion? get activeVersion => _activeVersion();
  bool get canUseVersions =>
      _currentProject != null &&
      _currentProject!.id > 0 &&
      _pendingEdits == null &&
      !_isProcessing &&
      !_isWaitingForAi;
  bool get hasPersistedProject =>
      _currentProject != null && _currentProject!.id > 0;
  bool get canOpenProjectSettings =>
      hasPersistedProject &&
      _pendingEdits == null &&
      !_isProcessing &&
      !_isWaitingForAi;
  bool get canUsePresets =>
      _photoEditingImage != null &&
      _pendingEdits == null &&
      !_isProcessing &&
      !_isWaitingForAi;
  bool get canSavePreset =>
      canUsePresets && !_currentEditState().activeOnly().isEmpty;
  String get defaultVersionName => 'Version ${_nextVersionSortOrder()}';
  String get defaultProjectName {
    final project = _currentProject;
    if (project == null) return 'Project';
    return suggestedSavedProjectName(project);
  }
  ui.Image? get processedImage => _processedPreviewImage;
  ui.Image? get originalPreviewImage => _originalPreviewImage;
  RgbaImageFrame? get presetThumbnailSourceFrame => _originalFrame;
  Uint8List? get originalBytes => _photoEditingImage?.originalBytes;
  String? get originalImagePath => _photoEditingImage?.originalImagePath;
  bool get isProcessing => _isProcessing;
  int? get lastBenchmarkMs => _lastBenchmarkMs; // temporary benchmark
  double? get exportProgress => _exportProgress;
  bool get canUndo => _pendingEdits == null && _history.canUndo;
  bool get canRedo => _pendingEdits == null && _history.canRedo;
  bool get isWaitingForAi => _isWaitingForAi;
  bool get isOnline => _isOnline;
  bool get isAiReady => _isAiReady;

  @override
  void dispose() {
    _disposePreviewImages();
    _editPipelineWorker.dispose();
    unawaited(_disposeOwnedProjectRepository?.call());
    unawaited(_disposeOwnedPresetRepository?.call());
    _connectivitySub.cancel();
    super.dispose();
  }

  OperationType get selectedOperation => _selectedOperation;
  ColorRange get selectedColorRange => _selectedColorRange;
  EditorMode get editorMode => _editorMode;
  ColorGradingZone get selectedGradingZone => _selectedGradingZone;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasPendingEdits => _pendingEdits != null;
  Set<OperationType> get pendingAiEditTypes =>
      _pendingEdits?.edits.map((e) => e.type).toSet() ?? {};
  Set<ColorRange> get pendingAiColorRanges =>
      _pendingEdits?.colorEdits.map((e) => e.range).toSet() ?? {};
  Set<ColorGradingZone> get pendingAiGradingZones =>
      _pendingEdits?.colorGradingEdits.map((e) => e.zone).toSet() ?? {};
  String? get pendingAiProviderId => _pendingAiProviderId;
  String get selectedModel => _activeProfile().model;
  String get selectedProvider => _activeProfile().providerId;
  AiProvider get aiProvider => _aiProvider;
  List<String> get availableModels => List.unmodifiable(_aiProvider.models);
  List<String> get availableProviders =>
      List.unmodifiable(_providerFactories.keys);
  AiProfileSettings get aiProfileSettings => _activeProfile();
  List<AiProfileSettings> get aiProfiles => List.unmodifiable(_aiProfiles);
  String get activeAiProfileId => _activeAiProfileId;
  Map<String, String> get aiProfileApiKeys =>
      Map.unmodifiable(_apiKeysByProfileId);

  List<String> modelsForProvider(String providerId) {
    final resolvedProviderId = _resolveProviderId(providerId);
    final providerFactory = _providerFactories[resolvedProviderId]!;
    final provider = providerFactory(null);
    return List.unmodifiable(provider.models);
  }

  void setSelectedModel(String model) {
    if (!_aiProvider.models.contains(model)) return;

    final active = _activeProfile();
    _replaceActiveProfile(active.copyWith(model: model));
    unawaited(_persistAiProfiles());
    notifyListeners();
  }

  Future<void> updateAiSettings(
    AiProfilesUpdate profilesUpdate,
    Map<String, String> apiKeysByProfileId,
  ) async {
    _applyAiProfilesUpdate(profilesUpdate);
    _apiKeysByProfileId = _normalizeApiKeys(
      apiKeysByProfileId,
      _aiProfiles.map((p) => p.id),
    );
    _initializeAiProvider();
    notifyListeners();
    await _persistApiKeys();
  }

  double getEditValue(OperationType type) {
    return _photoEditingImage?.getValue(type) ?? 0.0;
  }

  bool hasEdit(OperationType type) {
    return _photoEditingImage?.hasEdit(type) ?? false;
  }

  ColorEdit getColorEdit(ColorRange range) {
    return _photoEditingImage?.getColorEdit(range) ?? ColorEdit(range: range);
  }

  bool hasColorEdit(ColorRange range) {
    return _photoEditingImage?.hasColorEdit(range) ?? false;
  }

  ColorGradingEdit getColorGradingEdit(ColorGradingZone zone) {
    return _photoEditingImage?.getColorGradingEdit(zone) ??
        ColorGradingEdit(zone: zone);
  }

  bool hasColorGradingEdit(ColorGradingZone zone) {
    return _photoEditingImage?.hasColorGradingEdit(zone) ?? false;
  }

  void _disposePreviewImages() {
    _processedPreviewImage?.dispose();
    _processedPreviewImage = null;
    _originalPreviewImage?.dispose();
    _originalPreviewImage = null;
  }

  Future<ui.Image> _uiImageFromFrame(RgbaImageFrame frame) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      frame.rgbaBytes,
      frame.width,
      frame.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> _setProcessedFrame(RgbaImageFrame frame) async {
    final previewImage = await _uiImageFromFrame(frame);
    final previousPreviewImage = _processedPreviewImage;
    _processedPreviewImage = previewImage;
    _processedFrame = frame;
    previousPreviewImage?.dispose();
  }

  Future<void> importImageAsProject(String sourceImagePath) async {
    final importFolderId = _createTemporaryProjectFolderId();
    _currentProject = null;
    _versions = [];
    _activeVersionId = null;
    _messages.clear();
    _resetVersionHistories();
    _isProcessing = true;
    notifyListeners();

    try {
      final storedOriginal = await _projectFileStore.copyOriginalImage(
        sourcePath: sourceImagePath,
        projectId: importFolderId,
      );
      final imageInfo = await _previewImageDecoder.readImageInfo(
        storedOriginal.path,
      );

      await _loadImageFromPath(
        storedOriginal.path,
        manageProcessingState: false,
      );

      final previewFrame = _originalFrame!;
      final createdAt = _now();
      final project = EditorProject(
        name: unnamedDraftProjectName,
        status: EditorProjectStatus.draft,
        originalImagePath: storedOriginal.path,
        currentState: EditorEditState.empty(),
        originalWidth: imageInfo.width,
        originalHeight: imageInfo.height,
        previewWidth: previewFrame.width,
        previewHeight: previewFrame.height,
        createdAt: createdAt,
        updatedAt: createdAt,
        lastOpenedAt: createdAt,
      );

      var savedProject = await _saveProjectBestEffort(project);
      if (savedProject.id > 0) {
        await _projectFileStore.deleteProjectFiles(savedProject.id.toString());
        final finalOriginal = await _projectFileStore.moveOriginalImage(
          sourcePath: storedOriginal.path,
          projectId: savedProject.id.toString(),
        );
        unawaited(_projectFileStore.deleteProjectFiles(importFolderId));
        savedProject = savedProject.copyWith(
          originalImagePath: finalOriginal.path,
        );
        _photoEditingImage = PhotoEditingImage(
          originalBytes: _photoEditingImage!.originalBytes,
          originalImagePath: finalOriginal.path,
        );
        savedProject = await _saveProjectBestEffort(savedProject);
      }

      _currentProject = savedProject;
      if (savedProject.id > 0) {
        await _createInitialVersionBestEffort(savedProject);
        final currentProject = _currentProject;
        if (currentProject != null) {
          await _persistProjectPreviewBestEffort(
            currentProject,
            updatedAt: currentProject.updatedAt,
          );
        }
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> loadImageFromPath(String originalImagePath) async {
    _currentProject = null;
    _versions = [];
    _activeVersionId = null;
    _messages.clear();
    _resetVersionHistories();
    await _loadImageFromPath(originalImagePath);
  }

  Future<bool> loadProject(int projectId) async {
    _currentProject = null;
    _versions = [];
    _activeVersionId = null;
    _messages.clear();
    _resetVersionHistories();
    _isProcessing = true;
    notifyListeners();

    try {
      final project = await _projectRepositoryInstance.loadProject(projectId);
      if (project == null) return false;

      await _loadImageFromPath(
        project.originalImagePath,
        manageProcessingState: false,
      );

      var versions = await _projectRepositoryInstance.loadVersions(project.id);
      var activeVersion = _resolveActiveVersion(
        project.activeVersionId,
        versions,
      );
      if (activeVersion == null && versions.isEmpty) {
        activeVersion = _createVersion(
          project: project,
          sortOrder: 1,
          name: 'Version 1',
          parentVersionId: null,
          state: project.currentState,
          history: EditorHistory(),
        );
        versions = [activeVersion];
        await _saveVersionBestEffort(activeVersion);
      }
      final aiMessages = await _loadAiMessagesForScopeBestEffort(
        projectId: project.id,
        versionId: activeVersion?.id,
      );

      final restoredState = activeVersion?.state ?? project.currentState;
      restoredState.applyTo(_photoEditingImage!);
      final resultFrame = await _processAllEdits();
      await _setProcessedFrame(resultFrame);

      final openedAt = _now();
      _versions = versions;
      _messages
        ..clear()
        ..addAll(aiMessages);
      _currentProject = project.copyWith(
        activeVersionId: activeVersion?.id,
        currentState: restoredState,
        lastOpenedAt: openedAt,
      );
      if (activeVersion != null) {
        _activateVersionHistory(
          activeVersion.id,
          history: EditorHistory.fromSnapshot(activeVersion.history),
        );
        await _setActiveVersionBestEffort(
          projectId: project.id,
          versionId: activeVersion.id,
          state: restoredState,
          updatedAt: openedAt,
        );
      }
      await _markProjectOpenedBestEffort(project.id, openedAt);
      return true;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> saveCurrentDraftAsProject(String name) async {
    final project = _currentProject;
    final trimmedName = name.trim().isEmpty
        ? defaultProjectName
        : name.trim();
    if (project == null ||
        project.id <= 0 ||
        _photoEditingImage == null ||
        trimmedName.isEmpty) {
      return false;
    }

    final state = _currentEditState();
    final updatedAt = _now();
    await _projectRepositoryInstance.promoteDraftToSaved(
      projectId: project.id,
      name: trimmedName,
      state: state,
      updatedAt: updatedAt,
    );

    _currentProject = project.copyWith(
      name: trimmedName,
      status: EditorProjectStatus.saved,
      currentState: state,
      updatedAt: updatedAt,
    );
    await _persistProjectPreviewBestEffort(
      _currentProject!,
      updatedAt: updatedAt,
    );
    notifyListeners();
    return true;
  }

  Future<bool> refreshCurrentProjectMetadata() async {
    final project = _currentProject;
    if (project == null || project.id <= 0) return false;

    try {
      final latest = await _projectRepositoryInstance.loadProject(project.id);
      if (latest == null) return false;
      _currentProject = project.copyWith(
        name: latest.name,
        status: latest.status,
        previewImagePath: latest.previewImagePath,
        originalImagePath: latest.originalImagePath,
        originalWidth: latest.originalWidth,
        originalHeight: latest.originalHeight,
        previewWidth: latest.previewWidth,
        previewHeight: latest.previewHeight,
        createdAt: latest.createdAt,
        updatedAt: latest.updatedAt,
        lastOpenedAt: latest.lastOpenedAt,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ChatMessage>> _loadAiMessagesForScopeBestEffort({
    required int projectId,
    required String? versionId,
  }) async {
    try {
      if (versionId == null) {
        return await _projectRepositoryInstance.loadAiMessagesForProject(
          projectId,
        );
      }

      final versionMessages =
          await _projectRepositoryInstance.loadAiMessagesForVersion(
        projectId: projectId,
        versionId: versionId,
      );
      if (versionMessages.isNotEmpty) return versionMessages;

      final projectMessages =
          await _projectRepositoryInstance.loadAiMessagesForProject(projectId);
      if (projectMessages.isNotEmpty) {
        await _projectRepositoryInstance.moveProjectAiMessagesToVersion(
          projectId: projectId,
          versionId: versionId,
        );
      }
      return projectMessages;
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistAiMessageBestEffort(ChatMessage message) async {
    final project = _currentProject;
    if (project == null || project.id <= 0) return;
    final versionId = _activeVersionId;

    try {
      if (versionId == null) {
        await _projectRepositoryInstance.saveAiMessageForProject(
          projectId: project.id,
          message: message,
        );
      } else {
        await _projectRepositoryInstance.saveAiMessageForVersion(
          projectId: project.id,
          versionId: versionId,
          message: message,
        );
      }
    } catch (_) {
      // Chat persistence is best-effort; keep the live conversation intact.
    }
  }

  Future<void> _clearAiMessagesForScopeBestEffort({
    required int projectId,
    required String? versionId,
  }) async {
    try {
      if (versionId == null) {
        await _projectRepositoryInstance.clearAiMessagesForProject(projectId);
      } else {
        await _projectRepositoryInstance.clearAiMessagesForVersion(
          projectId: projectId,
          versionId: versionId,
        );
      }
    } catch (_) {
      // The editor should not crash if chat cleanup fails.
    }
  }

  Future<void> _cloneAiMessagesForVersionBestEffort({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {
    try {
      await _projectRepositoryInstance.cloneAiMessagesForVersion(
        projectId: projectId,
        sourceVersionId: sourceVersionId,
        targetVersionId: targetVersionId,
      );
    } catch (_) {
      // Version creation should still work if chat cloning fails.
    }
  }

  Future<void> _addChatMessage(ChatMessage message) async {
    _messages.add(message);
    await _persistAiMessageBestEffort(message);
  }

  Future<EditorVersion?> saveCurrentVersion({String? name}) async {
    final project = _currentProject;
    if (project == null ||
        project.id <= 0 ||
        _photoEditingImage == null ||
        _pendingEdits != null ||
        _isProcessing ||
        _isWaitingForAi) {
      return null;
    }

    await _persistCurrentProjectStateBestEffort();

    final sortOrder = _nextVersionSortOrder();
    final sourceVersionId = _activeVersionId;
    final version = _createVersion(
      project: project,
      sortOrder: sortOrder,
      name: _normalizeVersionName(name, sortOrder),
      parentVersionId: _activeVersionId,
      state: _currentEditState(),
      history: EditorHistory.copyOf(_history),
    );

    await _projectRepositoryInstance.saveVersion(version);
    if (sourceVersionId != null) {
      await _cloneAiMessagesForVersionBestEffort(
        projectId: project.id,
        sourceVersionId: sourceVersionId,
        targetVersionId: version.id,
      );
    }
    _versions = [..._versions, version];
    _activateVersionHistory(
      version.id,
      history: EditorHistory.copyOf(_history),
    );
    final updatedAt = _now();
    _currentProject = (_currentProject ?? project).copyWith(
      activeVersionId: version.id,
      currentState: version.state,
      updatedAt: updatedAt,
    );
    await _setActiveVersionBestEffort(
      projectId: project.id,
      versionId: version.id,
      state: version.state,
      updatedAt: updatedAt,
    );
    notifyListeners();
    return version;
  }

  Future<EditorVersion?> renameVersion(String versionId, String name) async {
    if (_pendingEdits != null || _isProcessing || _isWaitingForAi) {
      return null;
    }

    final trimmedName = _trimVersionName(name);
    if (trimmedName.isEmpty) return null;

    await _persistCurrentProjectStateBestEffort();

    final version = _versions.where((item) => item.id == versionId).firstOrNull;
    if (version == null) return null;

    final updatedVersion = version.copyWith(name: trimmedName);
    try {
      await _projectRepositoryInstance.saveVersion(updatedVersion);
    } catch (_) {
      return null;
    }

    _replaceVersion(updatedVersion);
    notifyListeners();
    return updatedVersion;
  }

  Future<bool> deleteVersion(String versionId) async {
    if (_photoEditingImage == null ||
        _pendingEdits != null ||
        _isProcessing ||
        _isWaitingForAi ||
        _versions.length <= 1) {
      return false;
    }

    final deleteIndex = _versions.indexWhere((version) => version.id == versionId);
    if (deleteIndex == -1) return false;

    final isActive = versionId == _activeVersionId;
    final fallbackVersion = isActive ? _fallbackVersionAfterDelete(deleteIndex) : null;
    if (isActive) {
      if (fallbackVersion == null) return false;
      final switched = await switchToVersion(fallbackVersion.id);
      if (switched == null) return false;
    }

    try {
      await _projectRepositoryInstance.deleteVersion(versionId);
    } catch (_) {
      return false;
    }

    _versions = [
      for (final version in _versions)
        if (version.id != versionId) version,
    ];
    _versionHistories.remove(_historyKeyForVersion(versionId));
    notifyListeners();
    return true;
  }

  Future<HistoryActionResult?> switchToVersion(String versionId) async {
    if (_photoEditingImage == null ||
        _pendingEdits != null ||
        _isProcessing ||
        _isWaitingForAi) {
      return null;
    }
    if (versionId == _activeVersionId) {
      final active = _activeVersion();
      return active == null ? null : HistoryActionResult(label: active.name);
    }

    await _persistCurrentProjectStateBestEffort();

    final version = _versions.where((item) => item.id == versionId).firstOrNull;
    if (version == null) return null;

    version.state.applyTo(_photoEditingImage!);
    _activateVersionHistory(
      version.id,
      history: _versionHistories[version.id] ??
          EditorHistory.fromSnapshot(version.history),
    );

    _isProcessing = true;
    notifyListeners();

    final resultFrame = await _processAllEdits();
    await _setProcessedFrame(resultFrame);

    final project = _currentProject;
    final updatedAt = _now();
    if (project != null && project.id > 0) {
      _currentProject = project.copyWith(
        activeVersionId: version.id,
        currentState: version.state,
        updatedAt: updatedAt,
      );
      await _setActiveVersionBestEffort(
        projectId: project.id,
        versionId: version.id,
        state: version.state,
        updatedAt: updatedAt,
      );
      await _persistProjectPreviewBestEffort(
        _currentProject!,
        updatedAt: updatedAt,
      );
      final aiMessages = await _loadAiMessagesForScopeBestEffort(
        projectId: project.id,
        versionId: version.id,
      );
      _messages
        ..clear()
        ..addAll(aiMessages);
    }

    _isProcessing = false;
    notifyListeners();
    return HistoryActionResult(label: version.name);
  }

  Future<void> _loadImageFromPath(
    String originalImagePath, {
    bool manageProcessingState = true,
  }) async {
    if (manageProcessingState) {
      _isProcessing = true;
      notifyListeners();
    }

    try {
      final originalFrame = await _previewImageDecoder.decodeFromPath(
        originalImagePath,
        maxDimension: 1080,
      );
      final originalPreviewImage = await _uiImageFromFrame(originalFrame);
      await _editPipelineWorker.loadOriginalFrame(originalFrame);

      _disposePreviewImages();
      _photoEditingImage = PhotoEditingImage(
        originalBytes: encodeJpgFromFrame(originalFrame),
        originalImagePath: originalImagePath,
      );
      _originalFrame = originalFrame;
      _originalPreviewImage = originalPreviewImage;
      _processedFrame = originalFrame;
      _processedPreviewImage = await _uiImageFromFrame(originalFrame);
      _snapshotProcessedFrame = null;
      _pendingEdits = null;
      _pendingAiHistoryEntry = null;
      _pendingAiProviderId = null;
      _manualEditBeforeState = null;
      _history.clear();
    } finally {
      if (manageProcessingState) {
        _isProcessing = false;
        notifyListeners();
      }
    }
  }

  Future<EditorProject> _saveProjectBestEffort(EditorProject project) async {
    try {
      return await _projectRepositoryInstance.saveProject(project);
    } catch (_) {
      // The editor can still use the imported image in memory.
      return project;
    }
  }

  Future<void> _markProjectOpenedBestEffort(
    int projectId,
    DateTime openedAt,
  ) async {
    try {
      await _projectRepositoryInstance.markProjectOpened(
        projectId: projectId,
        openedAt: openedAt,
      );
    } catch (_) {
      // Opening the project should not fail because recents metadata failed.
    }
  }

  EditorProjectRepository get _projectRepositoryInstance {
    final existing = _projectRepository;
    if (existing != null) return existing;

    final handle = createDefaultEditorProjectRepository();
    _disposeOwnedProjectRepository = handle.dispose;
    _projectRepository = handle.repository;
    return handle.repository;
  }

  PresetRepository get _presetRepositoryInstance {
    final existing = _presetRepository;
    if (existing != null) return existing;

    final handle = createDefaultPresetRepository();
    _disposeOwnedPresetRepository = handle.dispose;
    _presetRepository = handle.repository;
    return handle.repository;
  }

  String _createTemporaryProjectFolderId() {
    return 'import_${_now().microsecondsSinceEpoch}';
  }

  String _createVersionId(int projectId, int sortOrder) {
    return 'version_${projectId}_${sortOrder}_${_now().microsecondsSinceEpoch}';
  }

  int _nextVersionSortOrder() {
    var maxSortOrder = 0;
    for (final version in _versions) {
      if (version.sortOrder > maxSortOrder) {
        maxSortOrder = version.sortOrder;
      }
    }
    return maxSortOrder + 1;
  }

  EditorVersion _createVersion({
    required EditorProject project,
    required int sortOrder,
    required String name,
    required String? parentVersionId,
    required EditorEditState state,
    required EditorHistory history,
  }) {
    return EditorVersion(
      id: _createVersionId(project.id, sortOrder),
      projectId: project.id,
      name: name,
      parentVersionId: parentVersionId,
      state: state,
      history: history.toSnapshot(),
      sortOrder: sortOrder,
      createdAt: _now(),
    );
  }

  String _normalizeVersionName(String? name, int sortOrder) {
    final trimmed = _trimVersionName(name);
    if (trimmed.isEmpty) return 'Version $sortOrder';
    return trimmed;
  }

  String _trimVersionName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.length <= versionNameMaxLength) return trimmed;
    return trimmed.substring(0, versionNameMaxLength);
  }

  Future<void> _createInitialVersionBestEffort(EditorProject project) async {
    final version = _createVersion(
      project: project,
      sortOrder: 1,
      name: 'Version 1',
      parentVersionId: null,
      state: _currentEditState(),
      history: _history,
    );
    await _saveVersionBestEffort(version);
    _versions = [version];
    _activateVersionHistory(
      version.id,
      history: EditorHistory.fromSnapshot(version.history),
    );
    final updatedAt = _now();
    _currentProject = project.copyWith(
      activeVersionId: version.id,
      currentState: version.state,
      updatedAt: updatedAt,
    );
    await _setActiveVersionBestEffort(
      projectId: project.id,
      versionId: version.id,
      state: version.state,
      updatedAt: updatedAt,
    );
  }

  Future<void> _saveVersionBestEffort(EditorVersion version) async {
    try {
      await _projectRepositoryInstance.saveVersion(version);
    } catch (_) {
      // Version persistence should not block the editor from using the image.
    }
  }

  Future<void> _setActiveVersionBestEffort({
    required int projectId,
    required String? versionId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    try {
      await _projectRepositoryInstance.setActiveVersion(
        projectId: projectId,
        versionId: versionId,
        state: state,
        updatedAt: updatedAt,
      );
    } catch (_) {
      // The in-memory editor state remains valid if metadata persistence fails.
    }
  }

  EditorVersion? _resolveActiveVersion(
    String? activeVersionId,
    List<EditorVersion> versions,
  ) {
    if (versions.isEmpty) return null;
    if (activeVersionId != null) {
      final active = versions
          .where((version) => version.id == activeVersionId)
          .firstOrNull;
      if (active != null) return active;
    }
    return versions.first;
  }

  String _historyKeyForVersion(String? versionId) {
    return versionId ?? _projectHistoryKey;
  }

  void _resetVersionHistories() {
    _history = EditorHistory();
    _versionHistories
      ..clear()
      ..[_projectHistoryKey] = _history;
  }

  void _activateVersionHistory(String? versionId, {EditorHistory? history}) {
    _versionHistories[_historyKeyForVersion(_activeVersionId)] = _history;
    final key = _historyKeyForVersion(versionId);
    if (history != null) {
      _versionHistories[key] = history;
    } else if (!_versionHistories.containsKey(key)) {
      _versionHistories[key] = EditorHistory();
    }
    _activeVersionId = versionId;
    _history = _versionHistories[key]!;
  }

  EditorVersion? _activeVersion() {
    final versionId = _activeVersionId;
    if (versionId == null) return null;
    return _versions.where((version) => version.id == versionId).firstOrNull;
  }

  EditorVersion? _fallbackVersionAfterDelete(int deleteIndex) {
    if (_versions.length <= 1) return null;
    if (deleteIndex > 0) return _versions[deleteIndex - 1];
    return _versions[1];
  }

  void _replaceVersion(EditorVersion updatedVersion) {
    _versions = [
      for (final version in _versions)
        if (version.id == updatedVersion.id) updatedVersion else version,
    ];
  }

  void printLogs() {
    if (_photoEditingImage == null) return;
    final model = _photoEditingImage!;
    if (model.edits.isNotEmpty) {
      print('Edits:');
      for (final edit in model.edits) {
        print(edit.toString());
      }
    }
    if (model.colorEdits.isNotEmpty) {
      print('Color Edits:');
      for (final colorEdit in model.colorEdits) {
        print(colorEdit.toString());
      }
    }
    if (model.colorGradingEdits.isNotEmpty) {
      print('Color Grading Edits:');
      for (final gradingEdit in model.colorGradingEdits) {
        print(gradingEdit.toString());
      }
    }
    if (model.edits.isEmpty &&
        model.colorEdits.isEmpty &&
        model.colorGradingEdits.isEmpty) {
      print('No edits applied.');
    }
  }

  Future<void> resetEdits() async {
    if (_photoEditingImage == null || _originalFrame == null) return;
    _acceptPendingEditsForHistory();
    final before = _currentEditState();
    final after = EditorEditState.empty();

    _history.push(EditorHistoryEntry(
      before: before,
      after: after,
      label: 'Reset edits',
      source: EditorEditSource.reset,
    ));
    _photoEditingImage = PhotoEditingImage(
      originalBytes: _photoEditingImage!.originalBytes,
      originalImagePath: _photoEditingImage!.originalImagePath,
    );
    _snapshotProcessedFrame = null;
    _pendingEdits = null;
    _pendingAiHistoryEntry = null;
    _pendingAiProviderId = null;
    _manualEditBeforeState = null;
    _isProcessing = true;
    _editorMode = EditorMode.basic;
    _selectedOperation = OperationType.exposure;
    _selectedColorRange = ColorRange.red;
    _selectedGradingZone = ColorGradingZone.shadows;
    notifyListeners();

    await _setProcessedFrame(_originalFrame!);
    await _persistCurrentProjectStateBestEffort();

    _isProcessing = false;
    notifyListeners();
  }

  EditorEditState _currentEditState() {
    return EditorEditState.fromImage(_photoEditingImage!);
  }

  Future<String> defaultPresetName() async {
    final presets = await _presetRepositoryInstance.loadPresets();
    final names = presets
        .map((preset) => normalizeEditorPresetName(preset.name))
        .toSet();
    var suffix = 1;
    while (names.contains(normalizeEditorPresetName('Preset $suffix'))) {
      suffix++;
    }
    return 'Preset $suffix';
  }

  Future<EditorPreset> saveCurrentPreset(String name) async {
    if (!canUsePresets) {
      throw const PresetValidationException(
        'Presets are unavailable while the editor is busy.',
      );
    }

    return _presetRepositoryInstance.createPreset(
      name: name,
      state: _currentEditState().activeOnly(),
      createdAt: _now(),
    );
  }

  Future<HistoryActionResult?> applyPreset(
    EditorPreset preset,
    PresetApplyMode mode,
  ) async {
    final image = _photoEditingImage;
    if (image == null || !canUsePresets) return null;

    final before = _currentEditState();
    final recipe = preset.state.activeOnly();
    final after = switch (mode) {
      PresetApplyMode.merge => before.mergedWith(recipe),
      PresetApplyMode.replace => recipe,
    };
    if (before.contentEquals(after)) return null;
    final historyLabel = switch (mode) {
      PresetApplyMode.merge => 'Merged preset ${preset.name}',
      PresetApplyMode.replace => 'Replaced preset ${preset.name}',
    };

    _manualEditBeforeState = null;
    after.applyTo(image);
    _isProcessing = true;
    notifyListeners();

    try {
      final resultFrame = await _processAllEdits();
      await _setProcessedFrame(resultFrame);
      _pushHistoryEntry(
        before: before,
        label: historyLabel,
        source: EditorEditSource.preset,
      );
      await _persistCurrentProjectStateBestEffort();
      return HistoryActionResult(label: historyLabel);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void beginManualEdit() {
    if (_photoEditingImage == null) return;
    _manualEditBeforeState = _currentEditState();
  }

  void setSelectedOperation(OperationType op) {
    _selectedOperation = op;
    notifyListeners();
  }

  void setSelectedColorRange(ColorRange range) {
    _selectedColorRange = range;
    notifyListeners();
  }

  void setEditorMode(EditorMode mode) {
    _editorMode = mode;
    notifyListeners();
  }

  void setSelectedGradingZone(ColorGradingZone zone) {
    _selectedGradingZone = zone;
    notifyListeners();
  }

  void updateEditPreview(Edit edit) {
    if (_photoEditingImage == null) return;
    _photoEditingImage!.addOrUpdateEdit(edit);
    notifyListeners();
  }

  void updateColorEditPreview(ColorEdit colorEdit) {
    if (_photoEditingImage == null) return;
    _photoEditingImage!.addOrUpdateColorEdit(colorEdit);
    notifyListeners();
  }

  void updateColorGradingEditPreview(ColorGradingEdit edit) {
    if (_photoEditingImage == null) return;
    _photoEditingImage!.addOrUpdateColorGradingEdit(edit);
    notifyListeners();
  }

  Future<RgbaImageFrame> _processAllEdits() async {
    final model = _photoEditingImage!;
    if (model.edits.isEmpty &&
        model.colorEdits.isEmpty &&
        model.colorGradingEdits.isEmpty) {
      return _originalFrame!;
    }
    return await _editPipelineWorker.process(
      edits: model.edits,
      colorEdits: model.colorEdits,
      colorGradingEdits: model.colorGradingEdits,
    );
  }

  Future<void> applyEdit(Edit edit) async {
    if (_photoEditingImage == null) return;
    final before = _consumeManualEditBeforeState();
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateEdit(edit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    if (_pendingEdits == null) {
      _pushHistoryEntry(
        before: before,
        label: _basicEditHistoryLabel(edit),
        source: EditorEditSource.manual,
      );
      await _persistCurrentProjectStateBestEffort();
    }
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> applyColorEdit(ColorEdit colorEdit) async {
    if (_photoEditingImage == null) return;
    final before = _consumeManualEditBeforeState();
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateColorEdit(colorEdit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    if (_pendingEdits == null) {
      _pushHistoryEntry(
        before: before,
        label: _colorEditHistoryLabel(before, colorEdit),
        source: EditorEditSource.manual,
      );
      await _persistCurrentProjectStateBestEffort();
    }
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> applyColorGradingEdit(ColorGradingEdit edit) async {
    if (_photoEditingImage == null) return;
    final before = _consumeManualEditBeforeState();
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateColorGradingEdit(edit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    if (_pendingEdits == null) {
      _pushHistoryEntry(
        before: before,
        label: _colorGradingEditHistoryLabel(before, edit),
        source: EditorEditSource.manual,
      );
      await _persistCurrentProjectStateBestEffort();
    }
    _isProcessing = false;
    notifyListeners();
  }

  EditorEditState _consumeManualEditBeforeState() {
    final before = _manualEditBeforeState ?? _currentEditState();
    _manualEditBeforeState = null;
    return before;
  }

  void _pushHistoryEntry({
    required EditorEditState before,
    required String label,
    required EditorEditSource source,
  }) {
    _history.push(EditorHistoryEntry(
      before: before,
      after: _currentEditState(),
      label: label,
      source: source,
    ));
  }

  Future<void> _persistCurrentProjectStateBestEffort() async {
    final project = _currentProject;
    if (project == null || project.id <= 0 || _photoEditingImage == null) {
      return;
    }

    final state = _currentEditState();
    final updatedAt = _now();
    _currentProject = project.copyWith(
      activeVersionId: _activeVersionId,
      currentState: state,
      updatedAt: updatedAt,
    );

    try {
      final activeVersion = _activeVersion();
      if (activeVersion != null) {
        final updatedVersion = activeVersion.copyWith(
          state: state,
          history: _history.toSnapshot(),
        );
        _replaceVersion(updatedVersion);
        await _projectRepositoryInstance.saveVersion(updatedVersion);
        await _projectRepositoryInstance.setActiveVersion(
          projectId: project.id,
          versionId: updatedVersion.id,
          state: state,
          updatedAt: updatedAt,
        );
      } else {
        await _projectRepositoryInstance.saveCurrentState(
          projectId: project.id,
          state: state,
          updatedAt: updatedAt,
        );
      }
    } catch (_) {
      // Runtime editing should keep working even if persistence fails.
    }
    await _persistProjectPreviewBestEffort(
      _currentProject ?? project,
      updatedAt: updatedAt,
    );
  }

  Future<void> _persistProjectPreviewBestEffort(
    EditorProject project, {
    required DateTime updatedAt,
  }) async {
    final frame = _processedFrame;
    if (project.id <= 0 || frame == null) return;

    try {
      final currentProjectPreviewPath = _currentProject?.id == project.id
          ? _currentProject?.previewImagePath
          : null;
      final previousPreviewPath =
          currentProjectPreviewPath ?? project.previewImagePath;
      final previewPath = await _projectFileStore.projectPreviewImagePath(
        projectId: project.id.toString(),
        revision: _nextProjectPreviewRevision(updatedAt),
      );
      final thumbnailFrame = resizeRgbaFrameToFit(
        frame,
        maxDimension: _projectPreviewMaxDimension,
      );
      await File(previewPath).writeAsBytes(
        encodeJpgFromFrame(thumbnailFrame, quality: 80),
      );
      await _projectRepositoryInstance.updateProjectPreviewPath(
        projectId: project.id,
        previewImagePath: previewPath,
        updatedAt: updatedAt,
      );
      _currentProject = (_currentProject ?? project).copyWith(
        previewImagePath: previewPath,
        updatedAt: updatedAt,
      );
      await _deleteOldProjectPreviewBestEffort(
        previousPreviewPath,
        currentPreviewPath: previewPath,
      );
    } catch (_) {
      // Project browsing can fall back to a placeholder if preview persistence fails.
    }
  }

  String _nextProjectPreviewRevision(DateTime updatedAt) {
    final revision = _projectPreviewRevision++;
    return '${updatedAt.microsecondsSinceEpoch}_$revision';
  }

  Future<void> _deleteOldProjectPreviewBestEffort(
    String? previousPreviewPath, {
    required String currentPreviewPath,
  }) async {
    if (previousPreviewPath == null ||
        previousPreviewPath == currentPreviewPath) {
      return;
    }

    try {
      final oldPreview = File(previousPreviewPath);
      if (await oldPreview.exists()) {
        await oldPreview.delete();
      }
    } catch (_) {
      // Old previews are disposable cache files; a failed cleanup should not block editing.
    }
  }

  String _basicEditHistoryLabel(Edit edit) {
    return '${_humanizeName(edit.type.name)} ${_signedValue(edit.value)}';
  }

  String _colorEditHistoryLabel(EditorEditState before, ColorEdit colorEdit) {
    final previous = before.colorEdits
            .where((edit) => edit.range == colorEdit.range)
            .firstOrNull ??
        ColorEdit(range: colorEdit.range);
    final range = _humanizeName(colorEdit.range.name);

    if (previous.hue != colorEdit.hue) {
      return '$range hue ${_signedValue(colorEdit.hue)}';
    }
    if (previous.saturation != colorEdit.saturation) {
      return '$range saturation ${_signedValue(colorEdit.saturation)}';
    }
    if (previous.luminance != colorEdit.luminance) {
      return '$range luminance ${_signedValue(colorEdit.luminance)}';
    }
    return '$range color edit';
  }

  String _colorGradingEditHistoryLabel(
    EditorEditState before,
    ColorGradingEdit edit,
  ) {
    final previous = before.colorGradingEdits
            .where((gradingEdit) => gradingEdit.zone == edit.zone)
            .firstOrNull ??
        ColorGradingEdit(zone: edit.zone);
    final zone = _humanizeName(edit.zone.name);

    if (previous.hue != edit.hue) {
      return '$zone hue ${edit.hue.toStringAsFixed(0)}';
    }
    if (previous.strength != edit.strength) {
      return '$zone saturation ${_signedValue(edit.strength)}';
    }
    if (previous.luminance != edit.luminance) {
      return '$zone luminance ${_signedValue(edit.luminance)}';
    }
    return '$zone grading edit';
  }

  String _humanizeName(String name) {
    if (name.isEmpty) return name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _signedValue(double value) {
    final rounded = value.round();
    if (rounded > 0) return '+$rounded';
    return rounded.toString();
  }

  void _recordBenchmark(int ms) { // temporary benchmark
    _lastBenchmarkMs = ms;
    print('[BENCHMARK] Edit processing: ${ms}ms'); // temporary benchmark
  }

  Uint8List? _currentAiImageBytes() {
    final frame = _processedFrame ?? _originalFrame;
    if (frame == null) return _photoEditingImage?.originalBytes;
    return encodeJpgFromFrame(frame);
  }

  Future<String?> sendMessage(String text) async {
    if (text.trim().isEmpty) return null;
    if (_photoEditingImage == null) return 'No image loaded';
    final aiSettings = _activeProfile();
    final aiProviderId = _resolveProviderId(aiSettings.providerId);

    if (_pendingEdits != null) {
      applyPendingEdits();
    }

    final historyWindowSize = aiSettings.historyWindowSize;
    final history = _messages.length > historyWindowSize
        ? _messages.sublist(_messages.length - historyWindowSize)
        : List<ChatMessage>.from(_messages);
    final stateJson = _buildCurrentStateJson();

    await _addChatMessage(ChatMessage(text: text, type: MessageType.user));
    notifyListeners();

    _isWaitingForAi = true;
    notifyListeners();

    String aiReply;
    try {
      aiReply = await _sendWithRetry(text, history, stateJson, aiSettings.model);
    } on AiException catch (e) {
      _isWaitingForAi = false;
      await _addChatMessage(
        ChatMessage(text: e.message, type: MessageType.error),
      );
      notifyListeners();
      return null;
    } catch (e) {
      _isWaitingForAi = false;
      await _addChatMessage(
        ChatMessage(text: 'Unexpected error: $e', type: MessageType.error),
      );
      notifyListeners();
      return null;
    }

    _isWaitingForAi = false;

    var result = parseEditsJson(aiReply);
    if (result.error != null) {
      try {
        _isWaitingForAi = true;
        notifyListeners();
        aiReply = await _aiProvider.sendPrompt(
          'Your previous response had an error: ${result.error}. Fix and resend as valid JSON.',
          model: aiSettings.model,
          history: history,
          currentStateJson: stateJson,
        );
        _isWaitingForAi = false;
        result = parseEditsJson(aiReply);
      } on AiException catch (e) {
        _isWaitingForAi = false;
        await _addChatMessage(
          ChatMessage(text: e.message, type: MessageType.error),
        );
        notifyListeners();
        return null;
      } catch (_) {
        _isWaitingForAi = false;
      }

      if (result.error != null) {
        await _addChatMessage(
          ChatMessage(
            text:
                'AI returned invalid response after retrying. Error: ${result.error}.\nPlease try again.',
            type: MessageType.error,
          ),
        );
        notifyListeners();
        return null;
      }
    }

    final parsed = result.edits!;
    await _addChatMessage(
      ChatMessage(text: parsed.message ?? 'Edits applied.', type: MessageType.ai),
    );

    final model = _photoEditingImage!;
    final beforeAiEdit = _currentEditState();
    model.saveSnapshot();
    _snapshotProcessedFrame = _processedFrame;

    for (final edit in parsed.edits) {
      model.addOrUpdateEdit(edit);
    }
    for (final colorEdit in parsed.colorEdits) {
      model.addOrUpdateColorEdit(colorEdit);
    }
    for (final gradingEdit in parsed.colorGradingEdits) {
      model.addOrUpdateColorGradingEdit(gradingEdit);
    }
    final afterAiEdit = _currentEditState();
    _pendingAiHistoryEntry = EditorHistoryEntry(
      before: beforeAiEdit,
      after: afterAiEdit,
      label: 'AI edit',
      source: EditorEditSource.ai,
    );
    _pendingAiProviderId = aiProviderId;

    _isProcessing = true;
    notifyListeners();

    final resultFrame = await _processAllEdits();
    await _setProcessedFrame(resultFrame);
    _pendingEdits = parsed;
    _isProcessing = false;
    notifyListeners();
    return null;
  }

  Future<String> _sendWithRetry(
    String text,
    List<ChatMessage> history,
    String stateJson,
    String model,
  ) async {
    try {
      return await _aiProvider.sendPrompt(
        text,
        imageBytes: _currentAiImageBytes(),
        model: model,
        history: history,
        currentStateJson: stateJson,
      );
    } on AiException catch (e) {
      if (e.retryable) {
        return await _aiProvider.sendPrompt(
          text,
          imageBytes: _currentAiImageBytes(),
          model: model,
          history: history,
          currentStateJson: stateJson,
        );
      }
      rethrow;
    }
  }

  void applyPendingEdits() {
    _acceptPendingEditsForHistory();
    unawaited(_persistCurrentProjectStateBestEffort());
    notifyListeners();
  }

  bool _acceptPendingEditsForHistory() {
    if (_pendingEdits == null) return false;
    final entry = _pendingAiHistoryEntry;
    if (entry != null) {
      _history.push(EditorHistoryEntry(
        before: entry.before,
        after: _currentEditState(),
        label: entry.label,
        source: entry.source,
      ));
    }
    _pendingEdits = null;
    _pendingAiHistoryEntry = null;
    _pendingAiProviderId = null;
    _photoEditingImage?.clearSnapshot();
    _snapshotProcessedFrame = null;
    return true;
  }

  Future<void> discardPendingEdits() async {
    if (_pendingEdits == null) return;
    await _revertPendingEdits();
    notifyListeners();
  }

  Future<void> _revertPendingEdits() async {
    _photoEditingImage!.revertSnapshot();
    _pendingEdits = null;
    _pendingAiHistoryEntry = null;
    _pendingAiProviderId = null;

    if (_snapshotProcessedFrame != null) {
      await _setProcessedFrame(_snapshotProcessedFrame!);
    } else {
      final resultFrame = await _processAllEdits();
      await _setProcessedFrame(resultFrame);
    }

    _snapshotProcessedFrame = null;
  }

  Future<HistoryActionResult?> undo() async {
    if (_photoEditingImage == null) return null;
    if (_pendingEdits != null) {
      return null;
    }

    final entry = _history.undo();
    if (entry == null) return null;
    await _restoreEditState(entry.before);
    return HistoryActionResult(label: entry.label);
  }

  Future<HistoryActionResult?> redo() async {
    if (_photoEditingImage == null || _pendingEdits != null) return null;

    final entry = _history.redo();
    if (entry == null) return null;
    await _restoreEditState(entry.after);
    return HistoryActionResult(label: entry.label);
  }

  Future<void> _restoreEditState(EditorEditState state) async {
    final model = _photoEditingImage;
    if (model == null) return;

    _manualEditBeforeState = null;
    state.applyTo(model);
    _isProcessing = true;
    notifyListeners();

    final resultFrame = await _processAllEdits();
    await _setProcessedFrame(resultFrame);
    await _persistCurrentProjectStateBestEffort();

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> clearChat() async {
    final projectId = _currentProject?.id;
    final versionId = _activeVersionId;
    _messages.clear();
    notifyListeners();
    if (projectId != null && projectId > 0) {
      await _clearAiMessagesForScopeBestEffort(
        projectId: projectId,
        versionId: versionId,
      );
    }
  }

  ExportSettings get exportSettings => _exportSettings;

  void updateExportSettings(ExportSettings settings) {
    _exportSettings = settings;
    notifyListeners();
  }

  Future<void> exportToGallery() async {
    final model = _photoEditingImage;
    if (model == null) return;
    _setExportProgress(0.0);
    await _exportService.saveToGallery(
      originalImagePath: model.originalImagePath,
      edits: model.edits,
      colorEdits: model.colorEdits,
      colorGradingEdits: model.colorGradingEdits,
      settings: _exportSettings,
      onProgress: _setExportProgress,
    );
  }

  void _setExportProgress(double value) {
    _exportProgress = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  String _buildCurrentStateJson() {
    return _currentEditState().toJsonString(includeInactive: false);
  }
}
