import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_preset.dart';
import '../repositories/preset_repository.dart';
import '../repositories/preset_repository_factory.dart';

class PresetsViewModel extends ChangeNotifier {
  PresetsViewModel({
    PresetRepository? presetRepository,
  }) : _presetRepository = presetRepository;

  PresetRepository? _presetRepository;
  Future<void> Function()? _disposeOwnedPresetRepository;

  List<EditorPreset> _presets = [];
  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;

  List<EditorPreset> get presets => List.unmodifiable(_presets);
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get isEmpty => !_isLoading && _presets.isEmpty;
  String? get errorMessage => _errorMessage;

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
    unawaited(_disposeOwnedPresetRepository?.call());
    super.dispose();
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
