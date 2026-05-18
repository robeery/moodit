import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/services/project_file_store.dart';
import 'package:licenta/viewmodel/home_viewmodel.dart';

void main() {
  test('loads latest recoverable draft', () async {
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 7, status: EditorProjectStatus.draft));
    final vm = HomeViewModel(projectRepository: repository);
    addTearDown(vm.dispose);

    await vm.checkForRecoverableDraft();

    expect(repository.loadedDraftLimits, [1]);
    expect(vm.recoverableDraft?.id, 7);
    expect(vm.hasRecoverableDraft, isTrue);
  });

  test('discard deletes draft row and app-owned project files', () async {
    final tempDir = await Directory.systemTemp.createTemp('home_vm_test_');
    final projectDir = Directory('${tempDir.path}/projects/7');
    await projectDir.create(recursive: true);
    await File('${projectDir.path}/original.jpg').writeAsString('image');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 7, status: EditorProjectStatus.draft));
    final vm = HomeViewModel(
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    addTearDown(vm.dispose);

    await vm.checkForRecoverableDraft();
    final discarded = await vm.discardRecoverableDraft();

    expect(discarded, isTrue);
    expect(repository.deletedProjectIds, [7]);
    expect(vm.recoverableDraft, isNull);
    expect(await projectDir.exists(), isFalse);
  });

  test('save as project promotes draft and returns project id', () async {
    final updatedAt = DateTime.utc(2026, 5, 17, 10);
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(
      id: 7,
      status: EditorProjectStatus.draft,
      state: EditorEditState(
        edits: [Edit(type: OperationType.exposure, value: 20)],
        colorEdits: const [],
        colorGradingEdits: const [],
      ),
    ));
    final vm = HomeViewModel(
      projectRepository: repository,
      now: () => updatedAt,
    );
    addTearDown(vm.dispose);

    await vm.checkForRecoverableDraft();
    final projectId = await vm.saveRecoverableDraftAsProject('Recovered edit');

    expect(projectId, 7);
    expect(vm.recoverableDraft, isNull);
    expect(repository.promotedProjects.single.projectId, 7);
    expect(repository.promotedProjects.single.name, 'Recovered edit');
    expect(repository.promotedProjects.single.updatedAt, updatedAt);
    expect(repository.promotedProjects.single.state.edits.single.value, 20);
  });

  test('save as project falls back to project name for unnamed draft', () async {
    final updatedAt = DateTime.utc(2026, 5, 17, 10);
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(
      id: 7,
      name: unnamedDraftProjectName,
      status: EditorProjectStatus.draft,
    ));
    final vm = HomeViewModel(
      projectRepository: repository,
      now: () => updatedAt,
    );
    addTearDown(vm.dispose);

    await vm.checkForRecoverableDraft();

    expect(
      vm.suggestedProjectNameForDraft(vm.recoverableDraft!),
      'Project 7',
    );

    final projectId = await vm.saveRecoverableDraftAsProject('');

    expect(projectId, 7);
    expect(repository.promotedProjects.single.name, 'Project 7');
  });

  test('continue returns draft id and clears pending recovery', () async {
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 7, status: EditorProjectStatus.draft));
    final vm = HomeViewModel(projectRepository: repository);
    addTearDown(vm.dispose);

    await vm.checkForRecoverableDraft();
    final projectId = vm.continueRecoverableDraft();

    expect(projectId, 7);
    expect(vm.recoverableDraft, isNull);
  });
}

EditorProject _project({
  required int id,
  required EditorProjectStatus status,
  String? name,
  EditorEditState? state,
}) {
  final createdAt = DateTime.utc(2026, 5, 17, 9);
  return EditorProject(
    id: id,
    name: name ?? 'Project $id',
    status: status,
    originalImagePath: '/tmp/project_$id.jpg',
    currentState: state ?? EditorEditState.empty(),
    originalWidth: 16,
    originalHeight: 16,
    previewWidth: 16,
    previewHeight: 16,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
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
  final List<EditorProject> projects = [];
  final List<int> loadedDraftLimits = [];
  final List<int> deletedProjectIds = [];
  final List<_PromotedProject> promotedProjects = [];

  @override
  Future<void> deleteProject(int id) async {
    deletedProjectIds.add(id);
    projects.removeWhere((project) => project.id == id);
  }

  @override
  Future<void> deleteVersion(String id) async {}

  @override
  Future<EditorProject?> loadProject(int id) async {
    return projects.where((project) => project.id == id).firstOrNull;
  }

  @override
  Future<List<EditorProject>> loadRecentProjects({int limit = 20}) async {
    return projects
        .where((project) => project.status == EditorProjectStatus.saved)
        .take(limit)
        .toList();
  }

  @override
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20}) async {
    loadedDraftLimits.add(limit);
    return projects
        .where((project) => project.status == EditorProjectStatus.draft)
        .take(limit)
        .toList();
  }

  @override
  Future<EditorVersion?> loadVersion(String id) async => null;

  @override
  Future<List<EditorVersion>> loadVersions(int projectId) async => [];

  @override
  Future<void> markProjectOpened({
    required int projectId,
    required DateTime openedAt,
  }) async {}

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
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
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
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
      name: name,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> saveCurrentState({
    required int projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  }) async {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
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
  }) async {}

  @override
  Future<EditorProject> saveProject(EditorProject project) async {
    projects.add(project);
    return project;
  }

  @override
  Future<void> saveVersion(EditorVersion version) async {}
}
