import 'editor_edit_state.dart';

const int editorPresetNameMaxLength = 32;

String normalizeEditorPresetName(String name) => name.trim().toLowerCase();

class EditorPreset {
  const EditorPreset({
    required this.id,
    required this.name,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final EditorEditState state;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum PresetApplyMode {
  merge,
  replace,
}
