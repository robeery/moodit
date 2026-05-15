import 'color_edit.dart';
import 'color_grading_edit.dart';
import 'edit.dart';
import 'photo_editing_image.dart';

class EditorEditState {
  const EditorEditState({
    required this.edits,
    required this.colorEdits,
    required this.colorGradingEdits,
  });

  factory EditorEditState.fromImage(PhotoEditingImage image) {
    return EditorEditState(
      edits: List<Edit>.of(image.edits),
      colorEdits: List<ColorEdit>.of(image.colorEdits),
      colorGradingEdits: List<ColorGradingEdit>.of(image.colorGradingEdits),
    );
  }

  factory EditorEditState.empty() {
    return const EditorEditState(
      edits: [],
      colorEdits: [],
      colorGradingEdits: [],
    );
  }

  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> colorGradingEdits;

  bool contentEquals(EditorEditState other) {
    return _editListsEqual(edits, other.edits) &&
        _colorEditListsEqual(colorEdits, other.colorEdits) &&
        _colorGradingEditListsEqual(colorGradingEdits, other.colorGradingEdits);
  }

  void applyTo(PhotoEditingImage image) {
    image.edits
      ..clear()
      ..addAll(edits);
    image.colorEdits
      ..clear()
      ..addAll(colorEdits);
    image.colorGradingEdits
      ..clear()
      ..addAll(colorGradingEdits);
  }

  static bool _editListsEqual(List<Edit> a, List<Edit> b) {
    if (a.length != b.length) return false;
    for (final edit in a) {
      final match = b.where((e) => e.type == edit.type).firstOrNull;
      if (match == null || match.value != edit.value) return false;
    }
    return true;
  }

  static bool _colorEditListsEqual(List<ColorEdit> a, List<ColorEdit> b) {
    if (a.length != b.length) return false;
    for (final edit in a) {
      final match = b.where((e) => e.range == edit.range).firstOrNull;
      if (match == null ||
          match.hue != edit.hue ||
          match.saturation != edit.saturation ||
          match.luminance != edit.luminance) {
        return false;
      }
    }
    return true;
  }

  static bool _colorGradingEditListsEqual(
    List<ColorGradingEdit> a,
    List<ColorGradingEdit> b,
  ) {
    if (a.length != b.length) return false;
    for (final edit in a) {
      final match = b.where((e) => e.zone == edit.zone).firstOrNull;
      if (match == null ||
          match.hue != edit.hue ||
          match.strength != edit.strength ||
          match.luminance != edit.luminance) {
        return false;
      }
    }
    return true;
  }
}
