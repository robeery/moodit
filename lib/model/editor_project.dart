import 'editor_edit_state.dart';

class EditorProject {
  const EditorProject({
    required this.id,
    required this.name,
    required this.originalImagePath,
    required this.currentState,
    required this.originalWidth,
    required this.originalHeight,
    required this.previewWidth,
    required this.previewHeight,
    required this.createdAt,
    required this.updatedAt,
    this.previewImagePath,
    this.lastOpenedAt,
  });

  final String id;
  final String name;
  final String originalImagePath;
  final String? previewImagePath;
  final EditorEditState currentState;
  final int originalWidth;
  final int originalHeight;
  final int previewWidth;
  final int previewHeight;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;

  EditorProject copyWith({
    String? id,
    String? name,
    String? originalImagePath,
    Object? previewImagePath = _sentinel,
    EditorEditState? currentState,
    int? originalWidth,
    int? originalHeight,
    int? previewWidth,
    int? previewHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastOpenedAt = _sentinel,
  }) {
    return EditorProject(
      id: id ?? this.id,
      name: name ?? this.name,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      previewImagePath: identical(previewImagePath, _sentinel)
          ? this.previewImagePath
          : previewImagePath as String?,
      currentState: currentState ?? this.currentState,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: identical(lastOpenedAt, _sentinel)
          ? this.lastOpenedAt
          : lastOpenedAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
