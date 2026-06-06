import 'package:drift/drift.dart';

import '../../../model/editor_edit_state.dart';
import '../../../model/editor_history_snapshot.dart';
import '../../../model/editor_version.dart';
import '../app_database.dart';

extension EditorVersionRecordMapper on EditorVersionRecord {
  EditorVersion toModel() {
    return EditorVersion(
	      id: id,
	      projectId: projectId,
	      name: name,
	      parentVersionId: parentVersionId,
	      state: EditorEditState.fromJsonString(stateJson),
	      history: EditorHistorySnapshot.fromJsonString(historyJson),
	      thumbnailPath: thumbnailPath,
	      aiReferenceImagePath: aiReferenceImagePath,
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
	      parentVersionId: Value(parentVersionId),
	      stateJson: state.toJsonString(),
	      historyJson: Value(history.toJsonString()),
	      thumbnailPath: Value(thumbnailPath),
	      aiReferenceImagePath: Value(aiReferenceImagePath),
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}
