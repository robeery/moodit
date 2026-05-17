import 'package:drift/drift.dart';

import '../../../model/editor_edit_state.dart';
import '../../../model/editor_project.dart';
import '../app_database.dart';

extension EditorProjectRecordMapper on EditorProjectRecord {
  EditorProject toModel() {
    return EditorProject(
	      id: id,
	      name: name,
	      status: EditorProjectStatus.fromStorageValue(status),
	      activeVersionId: activeVersionId,
	      originalImagePath: originalImagePath,
      previewImagePath: previewImagePath,
      currentState: EditorEditState.fromJsonString(currentStateJson),
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: lastOpenedAt,
    );
  }
}

extension EditorProjectMapper on EditorProject {
  EditorProjectRecordsCompanion toRecordCompanion() {
    return EditorProjectRecordsCompanion(
	      id: id > 0 ? Value(id) : const Value.absent(),
	      name: Value(name),
	      status: Value(status.storageValue),
	      activeVersionId: Value(activeVersionId),
	      originalImagePath: Value(originalImagePath),
      previewImagePath: Value(previewImagePath),
      currentStateJson: Value(currentState.toJsonString()),
      originalWidth: Value(originalWidth),
      originalHeight: Value(originalHeight),
      previewWidth: Value(previewWidth),
      previewHeight: Value(previewHeight),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOpenedAt: Value(lastOpenedAt),
    );
  }
}
