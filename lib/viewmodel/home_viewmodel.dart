import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_project.dart';
import '../repositories/editor_project_repository.dart';
import '../repositories/editor_project_repository_factory.dart';
import '../services/project_file_store.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    EditorProjectRepository? projectRepository,
    ProjectFileStore? projectFileStore,
    DateTime Function()? now,
  })
      : _projectRepository = projectRepository,
        _projectFileStore = projectFileStore ?? ProjectFileStore(),
        _now = now ?? DateTime.now;

  EditorProjectRepository? _projectRepository;
  final ProjectFileStore _projectFileStore;
  final DateTime Function() _now;
  Future<void> Function()? _disposeOwnedProjectRepository;

  EditorProject? _recoverableDraft;
  bool _hasCheckedDraft = false;
  bool _isCheckingDraft = false;
  bool _isBusy = false;
  String? _errorMessage;

  EditorProject? get recoverableDraft => _recoverableDraft;
  bool get hasRecoverableDraft => _recoverableDraft != null;
  bool get hasCheckedDraft => _hasCheckedDraft;
  bool get isCheckingDraft => _isCheckingDraft;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

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
    final trimmedName = name.trim();
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
}
