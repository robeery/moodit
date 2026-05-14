import 'dart:typed_data';

import 'color_edit.dart';
import 'color_grading_edit.dart';
import 'edit.dart';

class PhotoEditingImage {
  final Uint8List originalBytes;
  final String originalImagePath;
  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> colorGradingEdits;

  PhotoEditingImage({
    required this.originalBytes,
    required this.originalImagePath,
    List<Edit>? edits,
    List<ColorEdit>? colorEdits,
    List<ColorGradingEdit>? colorGradingEdits,
  }) : edits = edits ?? [],
       colorEdits = colorEdits ?? [],
       colorGradingEdits = colorGradingEdits ?? [];


  void addOrUpdateEdit(Edit edit) {
    edits.removeWhere((e) => e.type == edit.type);
    edits.add(edit);
  }

  void removeEdit(OperationType type) {
    edits.removeWhere((e) => e.type == type);
  }

  double getValue(OperationType type) {
    return edits.where((e) => e.type == type).firstOrNull?.value ?? 0.0;
  }

  ColorEdit getColorEdit(ColorRange range) {
    return colorEdits.where((e) => e.range == range).firstOrNull ?? ColorEdit(range: range);
  }

  bool hasEdit(OperationType type) {
    return edits.any((e) => e.type == type && e.value.abs() > 0.001);
  }

  bool hasColorEdit(ColorRange range) {
    return colorEdits.any((e) => e.range == range && !e.isEmpty);
  }

  void addOrUpdateColorEdit(ColorEdit colorEdit) {
    colorEdits.removeWhere((e) => e.range == colorEdit.range);
    if (!colorEdit.isEmpty) {
      colorEdits.add(colorEdit);
    }
  }

  ColorGradingEdit getColorGradingEdit(ColorGradingZone zone) {
    return colorGradingEdits.where((e) => e.zone == zone).firstOrNull ??
        ColorGradingEdit(zone: zone);
  }

  bool hasColorGradingEdit(ColorGradingZone zone) {
    return colorGradingEdits.any((e) => e.zone == zone && !e.isEmpty);
  }

  void addOrUpdateColorGradingEdit(ColorGradingEdit edit) {
    colorGradingEdits.removeWhere((e) => e.zone == edit.zone);
    colorGradingEdits.add(edit);
  }

  // Snapshot support for pending AI edits
  List<Edit> _snapshotEdits = [];
  List<ColorEdit> _snapshotColorEdits = [];
  List<ColorGradingEdit> _snapshotGradingEdits = [];
  bool _hasSnapshot = false;

  bool get hasSnapshot => _hasSnapshot;

  void saveSnapshot() {
    _snapshotEdits = List.of(edits);
    _snapshotColorEdits = List.of(colorEdits);
    _snapshotGradingEdits = List.of(colorGradingEdits);
    _hasSnapshot = true;
  }

  void revertSnapshot() {
    if (!_hasSnapshot) return;
    edits..clear()..addAll(_snapshotEdits);
    colorEdits..clear()..addAll(_snapshotColorEdits);
    colorGradingEdits..clear()..addAll(_snapshotGradingEdits);
    _hasSnapshot = false;
  }

  void clearSnapshot() {
    _snapshotEdits = [];
    _snapshotColorEdits = [];
    _snapshotGradingEdits = [];
    _hasSnapshot = false;
  }
}
