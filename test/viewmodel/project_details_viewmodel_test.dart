import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/services/project_file_store.dart';
import 'package:licenta/viewmodel/project_details_viewmodel.dart';

void main() {
  test('loads project details and version count', () async {
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 3, name: 'Portrait'));
    repository.versions
      ..add(_version(projectId: 3, id: 'v1'))
      ..add(_version(projectId: 3, id: 'v2'));
    final vm = ProjectDetailsViewModel(
      projectId: 3,
      projectRepository: repository,
    );
    addTearDown(vm.dispose);

    await vm.loadProject();

    expect(vm.project?.name, 'Portrait');
    expect(vm.versionCount, 2);
    expect(vm.errorMessage, isNull);
  });

  test('renames project with max length', () async {
    final updatedAt = DateTime.utc(2026, 5, 18, 9);
    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 3, name: 'Portrait'));
    final vm = ProjectDetailsViewModel(
      projectId: 3,
      projectRepository: repository,
      now: () => updatedAt,
    );
    addTearDown(vm.dispose);

    await vm.loadProject();
    final renamed = await vm.renameProject(
      'A project name that is definitely longer than thirty two chars',
    );

    expect(renamed, isTrue);
    expect(vm.project?.name.length, ProjectDetailsViewModel.projectNameMaxLength);
    expect(repository.projects.single.name, vm.project?.name);
    expect(repository.projects.single.updatedAt, updatedAt);
  });

  test('delete removes project row, versions, and app-owned files', () async {
    final tempDir = await Directory.systemTemp.createTemp('details_vm_test_');
    final projectDir = Directory('${tempDir.path}/projects/3');
    await projectDir.create(recursive: true);
    await File('${projectDir.path}/original.jpg').writeAsString('image');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final repository = _FakeEditorProjectRepository();
    repository.projects.add(_project(id: 3, name: 'Portrait'));
    repository.versions.add(_version(projectId: 3, id: 'v1'));
    final vm = ProjectDetailsViewModel(
      projectId: 3,
      projectRepository: repository,
      projectFileStore: ProjectFileStore(
        documentsDirectoryProvider: () async => tempDir,
      ),
    );
    addTearDown(vm.dispose);

    await vm.loadProject();
    final deleted = await vm.deleteProject();

    expect(deleted, isTrue);
    expect(vm.wasDeleted, isTrue);
    expect(repository.projects, isEmpty);
    expect(repository.versions, isEmpty);
    expect(await projectDir.exists(), isFalse);
  });
}

EditorProject _project({
  required int id,
  required String name,
}) {
  final createdAt = DateTime.utc(2026, 5, 17, 9);
  return EditorProject(
    id: id,
    name: name,
    status: EditorProjectStatus.saved,
    originalImagePath: '/tmp/project_$id.jpg',
    currentState: EditorEditState.empty(),
    originalWidth: 4000,
    originalHeight: 3000,
    previewWidth: 1080,
    previewHeight: 810,
    createdAt: createdAt,
    updatedAt: createdAt,
    lastOpenedAt: createdAt,
  );
}

EditorVersion _version({
  required int projectId,
  required String id,
}) {
  return EditorVersion(
    id: id,
    projectId: projectId,
    name: id,
    state: EditorEditState.empty(),
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 5, 17, 9),
  );
}

class _FakeEditorProjectRepository implements EditorProjectRepository {
  final List<EditorProject> projects = [];
  final List<EditorVersion> versions = [];

  @override
  Future<void> deleteProject(int id) async {
    projects.removeWhere((project) => project.id == id);
    versions.removeWhere((version) => version.projectId == id);
  }

  @override
  Future<void> deleteVersion(String id) async {
    versions.removeWhere((version) => version.id == id);
  }

  @override
  Future<List<ChatMessage>> loadAiMessagesForProject(int projectId) async {
    return const [];
  }

  @override
  Future<void> saveAiMessageForProject({
    required int projectId,
    required ChatMessage message,
  }) async {}

  @override
  Future<void> clearAiMessagesForProject(int projectId) async {}

  @override
  Future<EditorProject?> loadProject(int id) async {
    return projects.where((project) => project.id == id).firstOrNull;
  }

  @override
  Future<List<EditorProject>> loadRecentProjects({int limit = 20}) async {
    return projects.take(limit).toList();
  }

  @override
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20}) async {
    return [];
  }

  @override
  Future<List<EditorVersion>> loadVersions(int projectId) async {
    return versions
        .where((version) => version.projectId == projectId)
        .toList();
  }

  @override
  Future<EditorVersion?> loadVersion(String id) async {
    return versions.where((version) => version.id == id).firstOrNull;
  }

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
  }) async {}

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
  Future<EditorProject> saveProject(EditorProject project) async => project;

  @override
  Future<void> saveVersion(EditorVersion version) async {}

  @override
  Future<void> setActiveVersion({
    required int projectId,
    required String? versionId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  }) async {}
}
