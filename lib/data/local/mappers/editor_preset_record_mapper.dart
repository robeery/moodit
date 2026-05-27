import 'package:drift/drift.dart';

import '../../../model/editor_edit_state.dart';
import '../../../model/editor_preset.dart';
import '../app_database.dart';

extension EditorPresetRecordMapper on EditorPresetRecord {
  EditorPreset toModel() {
    return EditorPreset(
      id: id,
      name: name,
      state: EditorEditState.fromJsonString(stateJson).activeOnly(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension EditorPresetMapper on EditorPreset {
  EditorPresetRecordsCompanion toRecordCompanion() {
    return EditorPresetRecordsCompanion(
      id: id > 0 ? Value(id) : const Value.absent(),
      name: Value(name),
      normalizedName: Value(normalizeEditorPresetName(name)),
      stateJson: Value(state.activeOnly().toJsonString()),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
