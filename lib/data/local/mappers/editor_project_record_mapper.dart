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
    return EditorProjectRecordsCompanion.insert(
      id: id,
      name: name,
      status: Value(status.storageValue),
      originalImagePath: originalImagePath,
      previewImagePath: Value(previewImagePath),
      currentStateJson: currentState.toJsonString(),
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: Value(lastOpenedAt),
    );
  }
}
