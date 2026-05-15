import 'dart:async';
import 'dart:convert';
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
import '../services/preview_image_decoder.dart';

enum EditorMode { basic, selectiveColor, colorGrading, askAi }

class EditorViewModel extends ChangeNotifier {
  final Map<String, AiProvider Function(String? apiKey)> _providerFactories = {
    AiProfileSettings.geminiProviderId: (apiKey) => GeminiProvider(apiKey: apiKey),
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
  final ExportService _exportService = ExportService();
  ExportSettings _exportSettings = const ExportSettings();
  ParsedEdits? _pendingEdits;
  EditorHistoryEntry? _pendingAiHistoryEntry;
  RgbaImageFrame? _snapshotProcessedFrame;
  final EditorHistory _history = EditorHistory();
  EditorEditState? _manualEditBeforeState;
  List<AiProfileSettings> _aiProfiles;
  String _activeAiProfileId;
  Map<String, String> _apiKeysByProfileId = {};

  EditorViewModel({
    AiProfilesStorage? aiProfilesStorage,
    AiProfilesApiKeyStorage? aiProfilesApiKeyStorage,
    EditPipelineWorker? editPipelineWorker,
    PreviewImageDecoder? previewImageDecoder,
  })
      : _aiProfiles = [const AiProfileSettings()],
        _activeAiProfileId = AiProfileSettings.defaultProfileId,
        _aiProfilesApiKeyStorage =
            aiProfilesApiKeyStorage ?? const AiProfilesApiKeyStorage(),
        _aiProfilesStorage = aiProfilesStorage ?? AiProfilesStorage(),
        _editPipelineWorker = editPipelineWorker ?? EditPipelineWorker(),
        _previewImageDecoder =
            previewImageDecoder ?? const PreviewImageDecoder() {
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
  ui.Image? get processedImage => _processedPreviewImage;
  ui.Image? get originalPreviewImage => _originalPreviewImage;
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

  Future<void> loadImageFromPath(String originalImagePath) async {
    _isProcessing = true;
    notifyListeners();

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
    _manualEditBeforeState = null;
    _history.clear();
    _isProcessing = false;
    notifyListeners();
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

  void resetEdits() {
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
    _manualEditBeforeState = null;
    unawaited(() async {
      await _setProcessedFrame(_originalFrame!);
      notifyListeners();
    }());
    _editorMode = EditorMode.basic;
    _selectedOperation = OperationType.exposure;
    _selectedColorRange = ColorRange.red;
    _selectedGradingZone = ColorGradingZone.shadows;
    notifyListeners();
  }

  EditorEditState _currentEditState() {
    return EditorEditState.fromImage(_photoEditingImage!);
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

    if (_pendingEdits != null) {
      applyPendingEdits();
    }

    final historyWindowSize = aiSettings.historyWindowSize;
    final history = _messages.length > historyWindowSize
        ? _messages.sublist(_messages.length - historyWindowSize)
        : List<ChatMessage>.from(_messages);
    final stateJson = _buildCurrentStateJson();

    _messages.add(ChatMessage(text: text, type: MessageType.user));
    notifyListeners();

    _isWaitingForAi = true;
    notifyListeners();

    String aiReply;
    try {
      aiReply = await _sendWithRetry(text, history, stateJson, aiSettings.model);
    } on AiException catch (e) {
      _isWaitingForAi = false;
      _messages.add(ChatMessage(text: e.message, type: MessageType.error));
      notifyListeners();
      return null;
    } catch (e) {
      _isWaitingForAi = false;
      _messages
          .add(ChatMessage(text: 'Unexpected error: $e', type: MessageType.error));
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
        _messages.add(ChatMessage(text: e.message, type: MessageType.error));
        notifyListeners();
        return null;
      } catch (_) {
        _isWaitingForAi = false;
      }

      if (result.error != null) {
        _messages.add(ChatMessage(
          text:
              'AI returned invalid response after retrying. Error: ${result.error}.\nPlease try again.',
          type: MessageType.error,
        ));
        notifyListeners();
        return null;
      }
    }

    final parsed = result.edits!;
    _messages.add(
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

    _isProcessing = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
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
    final model = _photoEditingImage!;
    return jsonEncode({
      'edits': model.edits.where((e) => e.value != 0).map((e) => e.toJson()).toList(),
      'colorEdits': model.colorEdits
          .where((e) => !e.isEmpty)
          .map((e) => e.toJson())
          .toList(),
      'colorGradingEdits': model.colorGradingEdits
          .where((e) => !e.isEmpty)
          .map((e) => e.toJson())
          .toList(),
    });
  }
}
