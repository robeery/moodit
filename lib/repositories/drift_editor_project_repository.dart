import '../data/local/app_database.dart';
import '../data/local/mappers/ai_chat_message_record_mapper.dart';
import '../data/local/mappers/editor_project_record_mapper.dart';
import '../data/local/mappers/editor_version_record_mapper.dart';
import '../model/chat_message.dart';
import '../model/editor_edit_state.dart';
import '../model/editor_project.dart';
import '../model/editor_version.dart';
import 'editor_project_repository.dart';

class DriftEditorProjectRepository implements EditorProjectRepository {
  const DriftEditorProjectRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<EditorProject>> loadRecentProjects({int limit = 20}) async {
    final records = await _database.editorProjectsDao.loadRecentProjects(
      status: EditorProjectStatus.saved.storageValue,
      limit: limit,
    );
    return records.map((record) => record.toModel()).toList();
  }

  @override
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20}) async {
    final records = await _database.editorProjectsDao.loadRecentProjects(
      status: EditorProjectStatus.draft.storageValue,
      limit: limit,
    );
    return records.map((record) => record.toModel()).toList();
  }

  @override
  Future<EditorProject?> loadProject(int id) async {
    final record = await _database.editorProjectsDao.findById(id);
    return record?.toModel();
  }

  @override
  Future<EditorProject> saveProject(EditorProject project) async {
    final id = await _database.editorProjectsDao.upsertProject(
      project.toRecordCompanion(),
    );
    return project.copyWith(id: project.id > 0 ? project.id : id);
  }

  @override
  Future<void> saveCurrentState({
    required int projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    await _database.editorProjectsDao.updateCurrentState(
      id: projectId,
      currentStateJson: state.toJsonString(),
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  }) async {
    await _database.editorProjectsDao.updatePreviewPath(
      id: projectId,
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
  }) async {
    await _database.editorProjectsDao.updateActiveVersion(
      id: projectId,
      activeVersionId: versionId,
      currentStateJson: state.toJsonString(),
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> promoteDraftToSaved({
    required int projectId,
    required String name,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    await _database.editorProjectsDao.promoteDraftToSaved(
      id: projectId,
      name: name,
      savedStatus: EditorProjectStatus.saved.storageValue,
      currentStateJson: state.toJsonString(),
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> renameProject({
    required int projectId,
    required String name,
    required DateTime updatedAt,
  }) async {
    await _database.editorProjectsDao.renameProject(
      id: projectId,
      name: name,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> markProjectOpened({
    required int projectId,
    required DateTime openedAt,
  }) async {
    await _database.editorProjectsDao.markOpened(
      id: projectId,
      openedAt: openedAt,
    );
  }

  @override
  Future<void> deleteProject(int id) async {
    await _database.transaction(() async {
      await _database.editorVersionsDao.deleteVersionsForProject(id);
      await _database.editorProjectsDao.deleteProject(id);
    });
  }

  @override
  Future<List<ChatMessage>> loadAiMessagesForProject(int projectId) async {
    final records = await _database.aiChatMessagesDao.loadForProject(projectId);
    return records.map((record) => record.toModel()).toList();
  }

  @override
  Future<void> saveAiMessageForProject({
    required int projectId,
    required ChatMessage message,
  }) async {
    final sortOrder =
        await _database.aiChatMessagesDao.nextSortOrderForProject(projectId);
    await _database.aiChatMessagesDao.insertMessage(
      message.toProjectRecordCompanion(
        projectId: projectId,
        sortOrder: sortOrder,
      ),
    );
  }

  @override
  Future<void> clearAiMessagesForProject(int projectId) async {
    await _database.aiChatMessagesDao.clearForProject(projectId);
  }

  @override
  Future<List<EditorVersion>> loadVersions(int projectId) async {
    final records = await _database.editorVersionsDao.loadForProject(projectId);
    return records.map((record) => record.toModel()).toList();
  }

  @override
  Future<EditorVersion?> loadVersion(String id) async {
    final record = await _database.editorVersionsDao.findById(id);
    return record?.toModel();
  }

  @override
  Future<void> saveVersion(EditorVersion version) {
    return _database.editorVersionsDao.upsertVersion(
      version.toRecordCompanion(),
    );
  }

  @override
  Future<void> deleteVersion(String id) async {
    await _database.editorVersionsDao.deleteVersion(id);
  }
}
