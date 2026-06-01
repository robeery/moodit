import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_preset.dart';
import '../repositories/preset_repository.dart';
import '../repositories/preset_repository_factory.dart';
import '../model/rgba_image_frame.dart';
import '../services/preset_thumbnail_service.dart';

class PresetsViewModel extends ChangeNotifier {
  PresetsViewModel({
    PresetRepository? presetRepository,
    RgbaImageFrame? thumbnailSourceFrame,
    PresetThumbnailService? thumbnailService,
  })  : _presetRepository = presetRepository,
        _thumbnailSourceFrame = thumbnailSourceFrame,
        _thumbnailService = thumbnailService ?? const PresetThumbnailService();

  PresetRepository? _presetRepository;
  final RgbaImageFrame? _thumbnailSourceFrame;
  final PresetThumbnailService _thumbnailService;
  Future<void> Function()? _disposeOwnedPresetRepository;

  List<EditorPreset> _presets = [];
  Map<int, Uint8List> _thumbnailsByPresetId = {};
  bool _isLoading = false;
  bool _isBusy = false;
  bool _isLoadingThumbnails = false;
  bool _isDisposed = false;
  int _thumbnailGeneration = 0;
  String? _errorMessage;

  List<EditorPreset> get presets => List.unmodifiable(_presets);
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get isLoadingThumbnails => _isLoadingThumbnails;
  bool get isEmpty => !_isLoading && _presets.isEmpty;
  String? get errorMessage => _errorMessage;

  Uint8List? thumbnailFor(EditorPreset preset) {
    return _thumbnailsByPresetId[preset.id];
  }

  Future<void> loadPresets() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _presets = await _presetRepositoryInstance.loadPresets();
    } on PresetRepositoryException catch (error) {
      _presets = [];
      _errorMessage = error.message;
    } catch (_) {
      _presets = [];
      _errorMessage = 'Could not load presets.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    unawaited(_refreshThumbnails());
  }

  Future<bool> renamePreset(EditorPreset preset, String name) async {
    if (_isBusy) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _presetRepositoryInstance.renamePreset(
        id: preset.id,
        name: name,
        updatedAt: DateTime.now(),
      );
      _presets = await _presetRepositoryInstance.loadPresets();
      _removeUnusedThumbnails();
      return true;
    } on PresetRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not rename preset.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> deletePreset(EditorPreset preset) async {
    if (_isBusy) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _presetRepositoryInstance.deletePreset(preset.id);
      _presets = await _presetRepositoryInstance.loadPresets();
      _removeUnusedThumbnails();
      return true;
    } on PresetRepositoryException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete preset.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_disposeOwnedPresetRepository?.call());
    super.dispose();
  }

  Future<void> _refreshThumbnails() async {
    final sourceFrame = _thumbnailSourceFrame;
    final presets = List<EditorPreset>.of(_presets);
    final generation = ++_thumbnailGeneration;

    if (sourceFrame == null || presets.isEmpty) {
      _thumbnailsByPresetId = {};
      return;
    }

    _isLoadingThumbnails = true;
    notifyListeners();

    try {
      final thumbnails = await _thumbnailService.buildThumbnails(
        originalFrame: sourceFrame,
        presets: presets,
      );
      if (_isDisposed || generation != _thumbnailGeneration) return;
      _thumbnailsByPresetId = thumbnails;
    } catch (_) {
      if (_isDisposed || generation != _thumbnailGeneration) return;
      _thumbnailsByPresetId = {};
    } finally {
      if (!_isDisposed && generation == _thumbnailGeneration) {
        _isLoadingThumbnails = false;
        notifyListeners();
      }
    }
  }

  void _removeUnusedThumbnails() {
    final presetIds = _presets.map((preset) => preset.id).toSet();
    _thumbnailsByPresetId = {
      for (final entry in _thumbnailsByPresetId.entries)
        if (presetIds.contains(entry.key)) entry.key: entry.value,
    };
  }

  PresetRepository get _presetRepositoryInstance {
    final existing = _presetRepository;
    if (existing != null) return existing;

    final handle = createDefaultPresetRepository();
    _disposeOwnedPresetRepository = handle.dispose;
    _presetRepository = handle.repository;
    return handle.repository;
  }
}
