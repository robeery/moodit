import '../model/editor_edit_state.dart';
import '../model/editor_project.dart';
import '../model/editor_version.dart';

abstract class EditorProjectRepository {
  Future<List<EditorProject>> loadRecentProjects({int limit = 20});
  Future<EditorProject?> loadProject(String id);
  Future<void> saveProject(EditorProject project);
  Future<void> saveCurrentState({
    required String projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  });
  Future<void> markProjectOpened({
    required String projectId,
    required DateTime openedAt,
  });
  Future<void> deleteProject(String id);

  Future<List<EditorVersion>> loadVersions(String projectId);
  Future<EditorVersion?> loadVersion(String id);
  Future<void> saveVersion(EditorVersion version);
  Future<void> deleteVersion(String id);
}
