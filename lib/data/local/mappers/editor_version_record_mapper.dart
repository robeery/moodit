import 'package:drift/drift.dart';

import '../../../model/editor_edit_state.dart';
import '../../../model/editor_version.dart';
import '../app_database.dart';

extension EditorVersionRecordMapper on EditorVersionRecord {
  EditorVersion toModel() {
    return EditorVersion(
      id: id,
      projectId: projectId,
      name: name,
      state: EditorEditState.fromJsonString(stateJson),
      thumbnailPath: thumbnailPath,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}

extension EditorVersionMapper on EditorVersion {
  EditorVersionRecordsCompanion toRecordCompanion() {
    return EditorVersionRecordsCompanion.insert(
      id: id,
      projectId: projectId,
      name: name,
      stateJson: state.toJsonString(),
      thumbnailPath: Value(thumbnailPath),
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}
