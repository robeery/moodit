import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_project.dart';
import '../model/editor_version.dart';
import '../repositories/editor_project_repository.dart';
import '../repositories/editor_project_repository_factory.dart';
import '../services/project_file_store.dart';

class ProjectDetailsViewModel extends ChangeNotifier {
  ProjectDetailsViewModel({
    required int projectId,
    EditorProjectRepository? projectRepository,
    ProjectFileStore? projectFileStore,
    DateTime Function()? now,
  })
      : _projectId = projectId,
        _projectRepository = projectRepository,
        _projectFileStore = projectFileStore ?? ProjectFileStore(),
        _now = now ?? DateTime.now;

  static const int projectNameMaxLength = 32;

  final int _projectId;
  EditorProjectRepository? _projectRepository;
  final ProjectFileStore _projectFileStore;
  final DateTime Function() _now;
  Future<void> Function()? _disposeOwnedProjectRepository;

  EditorProject? _project;
  List<EditorVersion> _versions = [];
  bool _isLoading = false;
  bool _isBusy = false;
  bool _wasDeleted = false;
  String? _errorMessage;

  EditorProject? get project => _project;
  List<EditorVersion> get versions => List.unmodifiable(_versions);
  int get versionCount => _versions.length;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get wasDeleted => _wasDeleted;
  String? get errorMessage => _errorMessage;

  Future<void> loadProject() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final project = await _projectRepositoryInstance.loadProject(_projectId);
      if (project == null) {
        _project = null;
        _versions = [];
        _errorMessage = 'Project not found.';
        return;
      }

      _project = project;
      _versions = await _projectRepositoryInstance.loadVersions(project.id);
    } catch (_) {
      _project = null;
      _versions = [];
      _errorMessage = 'Could not load project details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> renameProject(String name) async {
    final project = _project;
    final trimmedName = _trimProjectName(name);
    if (project == null || trimmedName.isEmpty || _isBusy) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAt = _now();
      await _projectRepositoryInstance.renameProject(
        projectId: project.id,
        name: trimmedName,
        updatedAt: updatedAt,
      );
      _project = project.copyWith(
        name: trimmedName,
        updatedAt: updatedAt,
      );
      return true;
    } catch (_) {
      _errorMessage = 'Could not rename project.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProject() async {
    final project = _project;
    if (project == null || _isBusy) return false;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectFileStore.deleteProjectFiles(project.id.toString());
      await _projectRepositoryInstance.deleteProject(project.id);
      _project = null;
      _versions = [];
      _wasDeleted = true;
      return true;
    } catch (_) {
      _errorMessage = 'Could not delete project.';
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
    unawaited(_disposeOwnedProjectRepository?.call());
    super.dispose();
  }

  String _trimProjectName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= projectNameMaxLength) return trimmed;
    return trimmed.substring(0, projectNameMaxLength);
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
