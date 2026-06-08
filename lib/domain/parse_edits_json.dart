import 'dart:convert';
import '../model/edit.dart';
import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';

class ParsedEdits {
  final String message;
  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> colorGradingEdits;

  const ParsedEdits({
    required this.message,
    this.edits = const [],
    this.colorEdits = const [],
    this.colorGradingEdits = const [],
  });

  bool get hasOperations =>
      edits.isNotEmpty ||
      colorEdits.isNotEmpty ||
      colorGradingEdits.isNotEmpty;
}

class ParseResult {
  final ParsedEdits? edits;
  final String? error;

  const ParseResult.success(ParsedEdits this.edits) : error = null;
  const ParseResult.failure(String this.error) : edits = null;
}

ParseResult parseEditsJson(String text) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const ParseResult.failure('Invalid JSON');
  }

  if (decoded is! Map<String, dynamic>) {
    return const ParseResult.failure('Expected a JSON object');
  }

  final allowedKeys = {'message', 'edits', 'colorEdits', 'colorGradingEdits'};
  for (final key in decoded.keys) {
    if (!allowedKeys.contains(key)) {
      return ParseResult.failure('Unknown key: "$key"');
    }
  }

  final message = decoded['message'];
  if (message is! String) {
    return const ParseResult.failure('"message" must be a string');
  }
  final normalizedMessage = message.trim();
  if (normalizedMessage.isEmpty) {
    return const ParseResult.failure('"message" must not be empty');
  }

  // Validate and parse basic edits
  final edits = <Edit>[];
  if (decoded.containsKey('edits')) {
    if (decoded['edits'] is! List) {
      return const ParseResult.failure('"edits" must be an array');
    }
    for (final item in decoded['edits']) {
      if (item is! Map<String, dynamic>) {
        return const ParseResult.failure('Each edit must be an object');
      }
      final typeStr = item['type'];
      final value = item['value'];
      if (typeStr is! String) {
        return const ParseResult.failure('Edit "type" must be a string');
      }
      if (value is! num) {
        return const ParseResult.failure('Edit "value" must be a number');
      }

      final OperationType type;
      try {
        type = OperationType.values.byName(typeStr);
      } catch (_) {
        return ParseResult.failure('Unknown operation type: "$typeStr"');
      }

      final v = value.toDouble();
      if (v < type.minValue || v > type.maxValue) {
        return ParseResult.failure(
          '"$typeStr" value $v out of range [${type.minValue.toInt()}, ${type.maxValue.toInt()}]',
        );
      }

      edits.add(Edit(type: type, value: v));
    }
  }

  // Validate and parse color edits
  final colorEdits = <ColorEdit>[];
  if (decoded.containsKey('colorEdits')) {
    if (decoded['colorEdits'] is! List) {
      return const ParseResult.failure('"colorEdits" must be an array');
    }
    for (final item in decoded['colorEdits']) {
      if (item is! Map<String, dynamic>) {
        return const ParseResult.failure('Each colorEdit must be an object');
      }
      final rangeStr = item['range'];
      if (rangeStr is! String) {
        return const ParseResult.failure('ColorEdit "range" must be a string');
      }

      final ColorRange range;
      try {
        range = ColorRange.values.byName(rangeStr);
      } catch (_) {
        return ParseResult.failure('Unknown color range: "$rangeStr"');
      }

      for (final field in ['hue', 'saturation', 'luminance']) {
        final v = item[field];
        if (v is! num) {
          return ParseResult.failure('ColorEdit "$field" must be a number');
        }
        if (v.toDouble() < -100 || v.toDouble() > 100) {
          return ParseResult.failure(
            'ColorEdit "$field" value $v out of range [-100, 100]',
          );
        }
      }

      colorEdits.add(ColorEdit(
        range: range,
        hue: (item['hue'] as num).toDouble(),
        saturation: (item['saturation'] as num).toDouble(),
        luminance: (item['luminance'] as num).toDouble(),
      ));
    }
  }

  // Validate and parse color grading edits
  final gradingEdits = <ColorGradingEdit>[];
  if (decoded.containsKey('colorGradingEdits')) {
    if (decoded['colorGradingEdits'] is! List) {
      return const ParseResult.failure(
        '"colorGradingEdits" must be an array',
      );
    }
    for (final item in decoded['colorGradingEdits']) {
      if (item is! Map<String, dynamic>) {
        return const ParseResult.failure(
          'Each colorGradingEdit must be an object',
        );
      }
      final zoneStr = item['zone'];
      if (zoneStr is! String) {
        return const ParseResult.failure(
          'ColorGradingEdit "zone" must be a string',
        );
      }

      final ColorGradingZone zone;
      try {
        zone = ColorGradingZone.values.byName(zoneStr);
      } catch (_) {
        return ParseResult.failure('Unknown grading zone: "$zoneStr"');
      }

      final hue = item['hue'];
      if (hue is! num) {
        return const ParseResult.failure(
          'ColorGradingEdit "hue" must be a number',
        );
      }
      if (hue.toDouble() < 0 || hue.toDouble() > 360) {
        return ParseResult.failure(
          'ColorGradingEdit "hue" value $hue out of range [0, 360]',
        );
      }

      final strength = item['strength'];
      if (strength is! num) {
        return const ParseResult.failure(
          'ColorGradingEdit "strength" must be a number',
        );
      }
      if (strength.toDouble() < 0 || strength.toDouble() > 100) {
        return ParseResult.failure(
          'ColorGradingEdit "strength" value $strength out of range [0, 100]',
        );
      }

      double lumValue = 0;
      if (item.containsKey('luminance')) {
        final lum = item['luminance'];
        if (lum is! num) {
          return const ParseResult.failure(
            'ColorGradingEdit "luminance" must be a number',
          );
        }
        if (lum.toDouble() < -100 || lum.toDouble() > 100) {
          return ParseResult.failure(
            'ColorGradingEdit "luminance" value $lum out of range [-100, 100]',
          );
        }
        lumValue = lum.toDouble();
      }

      gradingEdits.add(ColorGradingEdit(
        zone: zone,
        hue: hue.toDouble(),
        strength: strength.toDouble(),
        luminance: lumValue,
      ));
    }
  }

  return ParseResult.success(ParsedEdits(
    message: normalizedMessage,
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: gradingEdits,
  ));
}
