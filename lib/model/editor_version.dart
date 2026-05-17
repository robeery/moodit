import 'editor_edit_state.dart';
import 'editor_history_snapshot.dart';

class EditorVersion {
  const EditorVersion({
    required this.id,
    required this.projectId,
    required this.name,
    required this.state,
    required this.sortOrder,
    required this.createdAt,
    this.history = const EditorHistorySnapshot(
      undoEntries: [],
      redoEntries: [],
    ),
    this.parentVersionId,
    this.thumbnailPath,
  });

  final String id;
  final int projectId;
  final String name;
  final String? parentVersionId;
  final EditorEditState state;
  final EditorHistorySnapshot history;
  final String? thumbnailPath;
  final int sortOrder;
  final DateTime createdAt;

  EditorVersion copyWith({
    String? id,
    int? projectId,
    String? name,
    Object? parentVersionId = _sentinel,
    EditorEditState? state,
    EditorHistorySnapshot? history,
    Object? thumbnailPath = _sentinel,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EditorVersion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      parentVersionId: identical(parentVersionId, _sentinel)
          ? this.parentVersionId
          : parentVersionId as String?,
      state: state ?? this.state,
      history: history ?? this.history,
      thumbnailPath: identical(thumbnailPath, _sentinel)
          ? this.thumbnailPath
          : thumbnailPath as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const Object _sentinel = Object();
