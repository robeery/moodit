import 'editor_edit_state.dart';

class EditorVersion {
  const EditorVersion({
    required this.id,
    required this.projectId,
    required this.name,
    required this.state,
    required this.sortOrder,
    required this.createdAt,
    this.thumbnailPath,
  });

  final String id;
  final String projectId;
  final String name;
  final EditorEditState state;
  final String? thumbnailPath;
  final int sortOrder;
  final DateTime createdAt;

  EditorVersion copyWith({
    String? id,
    String? projectId,
    String? name,
    EditorEditState? state,
    Object? thumbnailPath = _sentinel,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EditorVersion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      state: state ?? this.state,
      thumbnailPath: identical(thumbnailPath, _sentinel)
          ? this.thumbnailPath
          : thumbnailPath as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const Object _sentinel = Object();
