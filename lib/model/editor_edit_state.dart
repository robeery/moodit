import 'dart:convert';

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

  factory EditorEditState.fromJson(Map<String, dynamic> json) {
    return EditorEditState(
      edits: _decodeList(json['edits'], Edit.fromJson),
      colorEdits: _decodeList(json['colorEdits'], ColorEdit.fromJson),
      colorGradingEdits: _decodeList(
        json['colorGradingEdits'],
        ColorGradingEdit.fromJson,
      ),
    );
  }

  factory EditorEditState.fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return EditorEditState.empty();
      return EditorEditState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return EditorEditState.empty();
    }
  }

  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> colorGradingEdits;

  bool get isEmpty =>
      edits.every((edit) => edit.value == 0) &&
      colorEdits.every((edit) => edit.isEmpty) &&
      colorGradingEdits.every((edit) => edit.isEmpty);

  EditorEditState activeOnly() {
    return EditorEditState(
      edits: edits.where((edit) => edit.value != 0).toList(),
      colorEdits: colorEdits.where((edit) => !edit.isEmpty).toList(),
      colorGradingEdits:
          colorGradingEdits.where((edit) => !edit.isEmpty).toList(),
    );
  }

  EditorEditState mergedWith(EditorEditState overlay) {
    final mergedEdits = {
      for (final edit in edits) edit.type: edit,
      for (final edit in overlay.edits) edit.type: edit,
    };
    final mergedColorEdits = {
      for (final edit in colorEdits) edit.range: edit,
      for (final edit in overlay.colorEdits) edit.range: edit,
    };
    final mergedColorGradingEdits = {
      for (final edit in colorGradingEdits) edit.zone: edit,
      for (final edit in overlay.colorGradingEdits) edit.zone: edit,
    };

    return EditorEditState(
      edits: mergedEdits.values.toList(),
      colorEdits: mergedColorEdits.values.toList(),
      colorGradingEdits: mergedColorGradingEdits.values.toList(),
    ).activeOnly();
  }

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

  Map<String, dynamic> toJson({bool includeInactive = true}) {
    return {
      'edits': (includeInactive
              ? edits
              : edits.where((edit) => edit.value != 0))
          .map((edit) => edit.toJson())
          .toList(),
      'colorEdits': (includeInactive
              ? colorEdits
              : colorEdits.where((edit) => !edit.isEmpty))
          .map((edit) => edit.toJson())
          .toList(),
      'colorGradingEdits': (includeInactive
              ? colorGradingEdits
              : colorGradingEdits.where((edit) => !edit.isEmpty))
          .map((edit) => edit.toJson())
          .toList(),
    };
  }

  String toJsonString({bool includeInactive = true}) {
    return jsonEncode(toJson(includeInactive: includeInactive));
  }

  static List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! List) return [];

    final result = <T>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        result.add(decode(Map<String, dynamic>.from(item)));
      } catch (_) {
       
      }
    }
    return result;
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
