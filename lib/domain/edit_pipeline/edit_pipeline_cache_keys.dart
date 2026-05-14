import '../../model/color_edit.dart';
import '../../model/edit.dart';

String buildBasicStageCacheKey({
  required int originalFrameRevision,
  required List<Edit> edits,
}) {
  final buffer = StringBuffer(originalFrameRevision);
  _writeBasicEditValues(buffer, edits);
  return buffer.toString();
}

String buildSelectiveStageCacheKey({
  required String basicStageCacheKey,
  required List<ColorEdit> colorEdits,
}) {
  final buffer = StringBuffer(basicStageCacheKey);
  buffer.write('|selective');
  final editValues = <ColorRange, ColorEdit>{
    for (final edit in colorEdits) edit.range: edit,
  };
  for (final range in ColorRange.values) {
    final edit = editValues[range];
    buffer
      ..write('|')
      ..write(range.index)
      ..write(':')
      ..write(edit?.hue ?? 0.0)
      ..write(',')
      ..write(edit?.saturation ?? 0.0)
      ..write(',')
      ..write(edit?.luminance ?? 0.0);
  }
  return buffer.toString();
}

void _writeBasicEditValues(StringBuffer buffer, List<Edit> edits) {
  final editValues = <OperationType, double>{
    for (final edit in edits) edit.type: edit.value,
  };
  for (final type in OperationType.values) {
    buffer
      ..write('|')
      ..write(type.index)
      ..write(':')
      ..write(editValues[type] ?? 0.0);
  }
}
