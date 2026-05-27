import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/data/local/app_database.dart';
import 'package:licenta/data/local/mappers/editor_preset_record_mapper.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';

void main() {
  test('preset mapper round-trips compact edit state', () {
    final createdAt = DateTime(2026, 6, 1, 12);
    final preset = EditorPreset(
      id: 4,
      name: '  Portrait Glow  ',
      state: EditorEditState(
        edits: [
          Edit(type: OperationType.brightness, value: 0),
          Edit(type: OperationType.contrast, value: 15),
        ],
        colorEdits: const [],
        colorGradingEdits: const [],
      ),
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final companion = preset.toRecordCompanion();
    final record = EditorPresetRecord(
      id: companion.id.value,
      name: companion.name.value,
      normalizedName: companion.normalizedName.value,
      stateJson: companion.stateJson.value,
      createdAt: companion.createdAt.value,
      updatedAt: companion.updatedAt.value,
    );
    final restored = record.toModel();

    expect(companion.normalizedName.value, 'portrait glow');
    expect(restored.state.edits.single.type, OperationType.contrast);
    expect(restored.state.edits.single.value, 15);
  });
}
