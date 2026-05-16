import '../data/local/app_database.dart';
import '../data/local/mappers/editor_project_record_mapper.dart';
import '../data/local/mappers/editor_version_record_mapper.dart';
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
  Future<EditorProject?> loadProject(String id) async {
    final record = await _database.editorProjectsDao.findById(id);
    return record?.toModel();
  }

  @override
  Future<void> saveProject(EditorProject project) {
    return _database.editorProjectsDao.upsertProject(
      project.toRecordCompanion(),
    );
  }

  @override
  Future<void> saveCurrentState({
    required String projectId,
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
  Future<void> promoteDraftToSaved({
    required String projectId,
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
  Future<void> markProjectOpened({
    required String projectId,
    required DateTime openedAt,
  }) async {
    await _database.editorProjectsDao.markOpened(
      id: projectId,
      openedAt: openedAt,
    );
  }

  @override
  Future<void> deleteProject(String id) async {
    await _database.editorProjectsDao.deleteProject(id);
  }

  @override
  Future<List<EditorVersion>> loadVersions(String projectId) async {
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
