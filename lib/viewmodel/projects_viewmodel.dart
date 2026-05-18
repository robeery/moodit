import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/editor_project.dart';
import '../repositories/editor_project_repository.dart';
import '../repositories/editor_project_repository_factory.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({
    EditorProjectRepository? projectRepository,
  }) : _projectRepository = projectRepository;

  EditorProjectRepository? _projectRepository;
  Future<void> Function()? _disposeOwnedProjectRepository;

  List<EditorProject> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EditorProject> get projects => List.unmodifiable(_projects);
  bool get isLoading => _isLoading;
  bool get isEmpty => !_isLoading && _projects.isEmpty;
  String? get errorMessage => _errorMessage;

  Future<void> loadProjects() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _projectRepositoryInstance.loadRecentProjects();
    } catch (_) {
      _projects = [];
      _errorMessage = 'Could not load projects.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProjects();

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
