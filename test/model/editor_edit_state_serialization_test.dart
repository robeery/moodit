import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';

void main() {
  test('empty edit state round-trips through JSON', () {
    final state = EditorEditState.empty();

    final restored = EditorEditState.fromJsonString(state.toJsonString());

    expect(restored.contentEquals(state), isTrue);
  });

  test('full edit state round-trips through JSON', () {
    final state = EditorEditState(
      edits: [
        Edit(type: OperationType.brightness, value: 30),
        Edit(type: OperationType.blur, value: 12),
      ],
      colorEdits: [
        ColorEdit(
          range: ColorRange.red,
          hue: -10,
          saturation: 25,
          luminance: -5,
        ),
      ],
      colorGradingEdits: [
        ColorGradingEdit(
          zone: ColorGradingZone.shadows,
          hue: 210,
          strength: 18,
          luminance: 4,
        ),
      ],
    );

    final restored = EditorEditState.fromJsonString(state.toJsonString());

    expect(restored.contentEquals(state), isTrue);
  });

  test('inactive entries can be omitted for AI current-state JSON', () {
    final state = EditorEditState(
      edits: [
        Edit(type: OperationType.brightness, value: 0),
        Edit(type: OperationType.contrast, value: 20),
      ],
      colorEdits: [
        ColorEdit(range: ColorRange.red),
        ColorEdit(range: ColorRange.blue, saturation: 15),
      ],
      colorGradingEdits: [
        ColorGradingEdit(zone: ColorGradingZone.shadows, hue: 220),
        ColorGradingEdit(zone: ColorGradingZone.highlights, luminance: 8),
      ],
    );

    final json = jsonDecode(
      state.toJsonString(includeInactive: false),
    ) as Map<String, dynamic>;

    expect(json['edits'], [
      {'type': 'contrast', 'value': 20.0},
    ]);
    expect(json['colorEdits'], [
      {'range': 'blue', 'hue': 0.0, 'saturation': 15.0, 'luminance': 0.0},
    ]);
    expect(json['colorGradingEdits'], [
      {'zone': 'highlights', 'hue': 0.0, 'strength': 0.0, 'luminance': 8.0},
    ]);
  });

  test('missing arrays default to empty lists', () {
    final state = EditorEditState.fromJsonString('{}');

    expect(state.edits, isEmpty);
    expect(state.colorEdits, isEmpty);
    expect(state.colorGradingEdits, isEmpty);
  });

  test('invalid JSON returns empty state', () {
    final state = EditorEditState.fromJsonString('not json');

    expect(state.contentEquals(EditorEditState.empty()), isTrue);
  });

  test('malformed persisted items are ignored', () {
    final state = EditorEditState.fromJsonString(jsonEncode({
      'edits': [
        {'type': 'brightness', 'value': 10},
        {'type': 'missingOperation', 'value': 80},
      ],
      'colorEdits': [
        {'range': 'red', 'saturation': 20},
        {'range': 'blue', 'hue': 900},
      ],
      'colorGradingEdits': [
        {'zone': 'midtones', 'strength': 30},
        {'zone': 'highlights', 'strength': 'bad'},
      ],
    }));

    expect(state.edits.single.type, OperationType.brightness);
    expect(state.edits.single.value, 10);
    expect(state.colorEdits.single.range, ColorRange.red);
    expect(state.colorEdits.single.saturation, 20);
    expect(state.colorGradingEdits.single.zone, ColorGradingZone.midtones);
    expect(state.colorGradingEdits.single.strength, 30);
  });
}
