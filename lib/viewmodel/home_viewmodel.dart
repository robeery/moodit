import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_project.dart';
import '../repositories/editor_project_repository.dart';
import '../repositories/editor_project_repository_factory.dart';
import '../repositories/preset_repository.dart';
import '../repositories/preset_repository_factory.dart';
import '../services/project_file_store.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    EditorProjectRepository? projectRepository,
    PresetRepository? presetRepository,
    ProjectFileStore? projectFileStore,
    DateTime Function()? now,
  })
      : _projectRepository = projectRepository,
        _presetRepository = presetRepository,
        _projectFileStore = projectFileStore ?? ProjectFileStore(),
        _now = now ?? DateTime.now;

  EditorProjectRepository? _projectRepository;
  PresetRepository? _presetRepository;
  final ProjectFileStore _projectFileStore;
  final DateTime Function() _now;
  Future<void> Function()? _disposeOwnedProjectRepository;
  Future<void> Function()? _disposeOwnedPresetRepository;

  // how many saved projects we scan for the home count and recent strip
  static const int _homeScanLimit = 99;
  static const int _recentDisplayCount = 3;

  EditorProject? _recoverableDraft;
  bool _hasCheckedDraft = false;
  bool _isCheckingDraft = false;
  bool _isBusy = false;
  String? _errorMessage;

  List<EditorProject> _recentProjects = const [];
  int _projectsCount = 0;
  int _presetsCount = 0;
  bool _isLoadingHomeData = false;
  bool _hasLoadedHomeData = false;

  EditorProject? get recoverableDraft => _recoverableDraft;
  bool get hasRecoverableDraft => _recoverableDraft != null;
  bool get hasCheckedDraft => _hasCheckedDraft;
  bool get isCheckingDraft => _isCheckingDraft;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  List<EditorProject> get recentProjects => _recentProjects;
  int get projectsCount => _projectsCount;
  int get presetsCount => _presetsCount;
  bool get isLoadingHomeData => _isLoadingHomeData;
  bool get hasLoadedHomeData => _hasLoadedHomeData;

  Future<void> loadHomeData({bool force = false}) async {
    if (_isLoadingHomeData || (_hasLoadedHomeData && !force)) return;

    _isLoadingHomeData = true;
    notifyListeners();

    try {
      final projects = await _projectRepositoryInstance.loadRecentProjects(
        limit: _homeScanLimit,
      );
      final presets = await _presetRepositoryInstance.loadPresets();
      _recentProjects = projects.take(_recentDisplayCount).toList();
      _projectsCount = projects.length;
      _presetsCount = presets.length;
    } catch (_) {
      // home counts are cosmetic, keep whatever we already had
    } finally {
      _hasLoadedHomeData = true;
      _isLoadingHomeData = false;
      notifyListeners();
    }
  }

  String suggestedProjectNameForDraft(EditorProject draft) {
    return suggestedSavedProjectName(draft);
  }

  Future<void> checkForRecoverableDraft({bool force = false}) async {
    if (_isCheckingDraft || (_hasCheckedDraft && !force)) return;

    _isCheckingDraft = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final drafts = await _projectRepositoryInstance.loadRecoverableDrafts(
        limit: 1,
      );
      _recoverableDraft = drafts.isEmpty ? null : drafts.first;
    } catch (_) {
      _recoverableDraft = null;
      _errorMessage = 'Could not check for drafts.';
    } finally {
      _hasCheckedDraft = true;
      _isCheckingDraft = false;
      notifyListeners();
    }
  }

  int? continueRecoverableDraft() {
    final draft = _recoverableDraft;
    if (draft == null) return null;

    _recoverableDraft = null;
    notifyListeners();
    return draft.id;
  }

  Future<bool> discardRecoverableDraft() async {
    final draft = _recoverableDraft;
    if (draft == null || _isBusy) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectRepositoryInstance.deleteProject(draft.id);
      try {
        await _projectFileStore.deleteProjectFiles(draft.id.toString());
      } catch (_) {
        // The draft should stay discarded even if old files could not be removed.
      }
      _recoverableDraft = null;
      return true;
    } catch (_) {
      _errorMessage = 'Could not discard draft.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<int?> saveRecoverableDraftAsProject(String name) async {
    final draft = _recoverableDraft;
    final trimmedName = name.trim().isEmpty && draft != null
        ? suggestedSavedProjectName(draft)
        : name.trim();
    if (draft == null || trimmedName.isEmpty || _isBusy) return null;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectRepositoryInstance.promoteDraftToSaved(
        projectId: draft.id,
        name: trimmedName,
        state: draft.currentState,
        updatedAt: _now(),
      );
      _recoverableDraft = null;
      return draft.id;
    } catch (_) {
      _errorMessage = 'Could not save draft.';
      return null;
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
    unawaited(_disposeOwnedProjectRepository?.call());
    unawaited(_disposeOwnedPresetRepository?.call());
    super.dispose();
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
}
