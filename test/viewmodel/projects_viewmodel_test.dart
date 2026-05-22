import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/viewmodel/projects_viewmodel.dart';

void main() {
  test('loads saved projects without drafts', () async {
    final repository = _FakeEditorProjectRepository();
    repository.projects
      ..add(_project(id: 1, name: 'Draft', status: EditorProjectStatus.draft))
      ..add(_project(id: 2, name: 'Saved', status: EditorProjectStatus.saved));
    final vm = ProjectsViewModel(projectRepository: repository);
    addTearDown(vm.dispose);

    await vm.loadProjects();

    expect(vm.projects, hasLength(1));
    expect(vm.projects.single.name, 'Saved');
    expect(vm.isEmpty, isFalse);
  });

  test('exposes empty state when no saved projects exist', () async {
    final repository = _FakeEditorProjectRepository();
    final vm = ProjectsViewModel(projectRepository: repository);
    addTearDown(vm.dispose);

    await vm.loadProjects();

    expect(vm.projects, isEmpty);
    expect(vm.isEmpty, isTrue);
  });
}

EditorProject _project({
  required int id,
  required String name,
  required EditorProjectStatus status,
}) {
  final createdAt = DateTime.utc(2026, 5, 17, 9);
  return EditorProject(
    id: id,
    name: name,
    status: status,
    originalImagePath: '/tmp/project_$id.jpg',
    currentState: EditorEditState.empty(),
    originalWidth: 16,
    originalHeight: 16,
    previewWidth: 16,
    previewHeight: 16,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _FakeEditorProjectRepository implements EditorProjectRepository {
  final List<EditorProject> projects = [];

  @override
  Future<void> deleteProject(int id) async {}

  @override
  Future<void> deleteVersion(String id) async {}

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
  Future<List<ChatMessage>> loadAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {
    return const [];
  }

  @override
  Future<void> saveAiMessageForVersion({
    required int projectId,
    required String versionId,
    required ChatMessage message,
  }) async {}

  @override
  Future<void> cloneAiMessagesForVersion({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {}

  @override
  Future<void> moveProjectAiMessagesToVersion({
    required int projectId,
    required String versionId,
  }) async {}

  @override
  Future<void> clearAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {}

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
  }) async {}

  @override
  Future<void> renameProject({
    required int projectId,
    required String name,
    required DateTime updatedAt,
  }) async {}

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
}
