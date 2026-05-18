import 'editor_edit_state.dart';

const String unnamedDraftProjectName = 'Unnamed draft';
final RegExp _generatedNumericDraftName = RegExp(r'^\d{10,}$');
final RegExp _generatedUuidDraftName = RegExp(
  r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
);

enum EditorProjectStatus {
  draft('draft'),
  saved('saved');

  const EditorProjectStatus(this.storageValue);

  final String storageValue;

  static EditorProjectStatus fromStorageValue(String value) {
    for (final status in EditorProjectStatus.values) {
      if (status.storageValue == value) return status;
    }
    return EditorProjectStatus.draft;
  }
}

String suggestedSavedProjectName(EditorProject project) {
  final displayName = displayProjectName(project);
  if (displayName.isEmpty ||
      (project.status == EditorProjectStatus.draft &&
          displayName == unnamedDraftProjectName)) {
    return project.id > 0 ? 'Project ${project.id}' : 'Project';
  }
  return displayName;
}

String displayProjectName(EditorProject project) {
  final trimmedName = project.name.trim();
  if (project.status == EditorProjectStatus.draft &&
      (trimmedName.isEmpty || isGeneratedDraftProjectName(trimmedName))) {
    return unnamedDraftProjectName;
  }
  return trimmedName.isEmpty ? 'Project ${project.id}' : trimmedName;
}

bool isGeneratedDraftProjectName(String name) {
  final trimmedName = name.trim();
  return trimmedName == unnamedDraftProjectName ||
      trimmedName.startsWith('import_') ||
      trimmedName.startsWith('image_picker_') ||
      _generatedNumericDraftName.hasMatch(trimmedName) ||
      _generatedUuidDraftName.hasMatch(trimmedName);
}

class EditorProject {
  const EditorProject({
    this.id = 0,
    required this.name,
    required this.originalImagePath,
    required this.currentState,
    required this.originalWidth,
    required this.originalHeight,
    required this.previewWidth,
    required this.previewHeight,
    required this.createdAt,
    required this.updatedAt,
    this.status = EditorProjectStatus.draft,
    this.activeVersionId,
    this.previewImagePath,
    this.lastOpenedAt,
  });

  final int id;
  final String name;
  final EditorProjectStatus status;
  final String? activeVersionId;
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
    int? id,
    String? name,
    EditorProjectStatus? status,
    Object? activeVersionId = _sentinel,
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
      status: status ?? this.status,
      activeVersionId: identical(activeVersionId, _sentinel)
          ? this.activeVersionId
          : activeVersionId as String?,
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
