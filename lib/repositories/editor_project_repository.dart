import '../model/chat_message.dart';
import '../model/editor_edit_state.dart';
import '../model/editor_project.dart';
import '../model/editor_version.dart';

abstract class EditorProjectRepository {
  Future<List<EditorProject>> loadRecentProjects({int limit = 20});
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20});
  Future<EditorProject?> loadProject(int id);
  Future<EditorProject> saveProject(EditorProject project);
  Future<void> saveCurrentState({
    required int projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  });
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  });
  Future<void> setActiveVersion({
    required int projectId,
    required String? versionId,
    required EditorEditState state,
    required DateTime updatedAt,
  });
  Future<void> promoteDraftToSaved({
    required int projectId,
    required String name,
    required EditorEditState state,
    required DateTime updatedAt,
  });
  Future<void> renameProject({
    required int projectId,
    required String name,
    required DateTime updatedAt,
  });
  Future<void> markProjectOpened({
    required int projectId,
    required DateTime openedAt,
  });
  Future<void> deleteProject(int id);
  Future<List<ChatMessage>> loadAiMessagesForProject(int projectId);
  Future<void> saveAiMessageForProject({
    required int projectId,
    required ChatMessage message,
  });
  Future<void> clearAiMessagesForProject(int projectId);
  Future<List<ChatMessage>> loadAiMessagesForVersion({
    required int projectId,
    required String versionId,
  });
  Future<void> saveAiMessageForVersion({
    required int projectId,
    required String versionId,
    required ChatMessage message,
  });
  Future<void> cloneAiMessagesForVersion({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  });
  Future<void> moveProjectAiMessagesToVersion({
    required int projectId,
    required String versionId,
  });
  Future<void> clearAiMessagesForVersion({
    required int projectId,
    required String versionId,
  });

  Future<List<EditorVersion>> loadVersions(int projectId);
  Future<EditorVersion?> loadVersion(String id);
  Future<void> saveVersion(EditorVersion version);
  Future<void> deleteVersion(String id);
}
