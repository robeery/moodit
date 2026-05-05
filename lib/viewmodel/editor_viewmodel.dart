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
import '../model/photo_editing_image.dart';
import '../model/rgba_image_frame.dart';
import '../domain/apply_edits.dart';
import '../domain/parse_edits_json.dart';
import '../model/chat_message.dart';
import '../model/export_settings.dart';
import '../domain/ai_provider.dart';
import '../services/ai_profiles_api_key_storage.dart';
import '../services/ai_profiles_storage.dart';
import '../services/edit_pipeline_worker.dart';
import '../services/export_service.dart';
import '../services/gemini_provider.dart';

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
  final ExportService _exportService = ExportService();
  ExportSettings _exportSettings = const ExportSettings();
  ParsedEdits? _pendingEdits;
  RgbaImageFrame? _snapshotProcessedFrame;
  List<AiProfileSettings> _aiProfiles;
  String _activeAiProfileId;
  Map<String, String> _apiKeysByProfileId = {};

  EditorViewModel({
    AiProfilesStorage? aiProfilesStorage,
    AiProfilesApiKeyStorage? aiProfilesApiKeyStorage,
    EditPipelineWorker? editPipelineWorker,
  })
      : _aiProfiles = [const AiProfileSettings()],
        _activeAiProfileId = AiProfileSettings.defaultProfileId,
        _aiProfilesApiKeyStorage =
            aiProfilesApiKeyStorage ?? const AiProfilesApiKeyStorage(),
        _aiProfilesStorage = aiProfilesStorage ?? AiProfilesStorage(),
        _editPipelineWorker = editPipelineWorker ?? EditPipelineWorker() {
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
  bool get isProcessing => _isProcessing;
  int? get lastBenchmarkMs => _lastBenchmarkMs; // temporary benchmark
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

  Future<void> loadImage(Uint8List bytes) async {
    _isProcessing = true;
    notifyListeners();

    final originalFrame = decodeRgbaImageFrame(bytes);
    final originalPreviewImage = await _uiImageFromFrame(originalFrame);
    await _editPipelineWorker.loadOriginalFrame(originalFrame);

    _disposePreviewImages();
    _photoEditingImage = PhotoEditingImage(originalBytes: bytes);
    _originalFrame = originalFrame;
    _originalPreviewImage = originalPreviewImage;
    _processedFrame = originalFrame;
    _processedPreviewImage = await _uiImageFromFrame(originalFrame);
    _snapshotProcessedFrame = null;
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
    _photoEditingImage = PhotoEditingImage(
      originalBytes: _photoEditingImage!.originalBytes,
    );
    _snapshotProcessedFrame = null;
    _pendingEdits = null;
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
    _photoEditingImage!.addOrUpdateEdit(edit);
    notifyListeners();
  }

  void updateColorEditPreview(ColorEdit colorEdit) {
    _photoEditingImage!.addOrUpdateColorEdit(colorEdit);
    notifyListeners();
  }

  void updateColorGradingEditPreview(ColorGradingEdit edit) {
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
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateEdit(edit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> applyColorEdit(ColorEdit colorEdit) async {
    if (_photoEditingImage == null) return;
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateColorEdit(colorEdit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    _isProcessing = false;
    notifyListeners();
  }

  Future<void> applyColorGradingEdit(ColorGradingEdit edit) async {
    if (_photoEditingImage == null) return;
    _isProcessing = true;
    notifyListeners();

    final sw = Stopwatch()..start(); // temporary benchmark
    _photoEditingImage!.addOrUpdateColorGradingEdit(edit);
    final result = await _processAllEdits();
    sw.stop(); // temporary benchmark
    _recordBenchmark(sw.elapsedMilliseconds); // temporary benchmark

    await _setProcessedFrame(result);
    _isProcessing = false;
    notifyListeners();
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
    _pendingEdits = null;
    _photoEditingImage?.clearSnapshot();
    _snapshotProcessedFrame = null;
    notifyListeners();
  }

  Future<void> discardPendingEdits() async {
    if (_pendingEdits == null) return;
    await _revertPendingEdits();
    notifyListeners();
  }

  Future<void> _revertPendingEdits() async {
    _photoEditingImage!.revertSnapshot();
    _pendingEdits = null;

    if (_snapshotProcessedFrame != null) {
      await _setProcessedFrame(_snapshotProcessedFrame!);
    } else {
      final resultFrame = await _processAllEdits();
      await _setProcessedFrame(resultFrame);
    }

    _snapshotProcessedFrame = null;
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
    final frame = _processedFrame ?? _originalFrame;
    if (frame == null) return;
    await _exportService.saveToGallery(frame, _exportSettings);
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
