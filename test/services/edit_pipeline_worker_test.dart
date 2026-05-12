import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/domain/apply_edits.dart';
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/rgba_image_frame.dart';
import 'package:licenta/services/edit_pipeline_worker.dart';

void main() {
  test('persistent worker matches the synchronous pipeline', () async {
    const width = 8;
    const height = 6;
    final bytes = Uint8List(width * height * 4);
    int byte(int value) => value.clamp(0, 255).toInt();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        bytes[offset] = byte(24 + x * 19 + y * 7);
        bytes[offset + 1] = byte(32 + x * 5 + y * 23);
        bytes[offset + 2] = byte(48 + x * 13 + y * 11);
        bytes[offset + 3] = 255;
      }
    }

    final frame = RgbaImageFrame(
      rgbaBytes: bytes,
      width: width,
      height: height,
    );
    final edits = [
      Edit(type: OperationType.exposure, value: 25),
      Edit(type: OperationType.contrast, value: 15),
      Edit(type: OperationType.vibrance, value: 20),
    ];
    final colorEdits = [
      ColorEdit(range: ColorRange.red, hue: 10, saturation: 15, luminance: 5),
      ColorEdit(range: ColorRange.blue, hue: -8, saturation: 12, luminance: -4),
    ];
    final gradingEdits = [
      ColorGradingEdit(
        zone: ColorGradingZone.global,
        hue: 180,
        strength: 20,
        luminance: 5,
      ),
    ];

    final expected = applyEditsToRgbaSync(
      originalFrame: frame,
      edits: edits,
      colorEdits: colorEdits,
      colorGradingEdits: gradingEdits,
    );

    final worker = EditPipelineWorker();
    addTearDown(worker.dispose);
    await worker.loadOriginalFrame(frame);
    final result = await worker.process(
      edits: edits,
      colorEdits: colorEdits,
      colorGradingEdits: gradingEdits,
    );

    expect(result.width, expected.width);
    expect(result.height, expected.height);
    expect(result.rgbaBytes, orderedEquals(expected.rgbaBytes));

    final secondColorEdits = [
      ColorEdit(range: ColorRange.red, hue: -20, saturation: 25, luminance: 5),
      ColorEdit(range: ColorRange.blue, hue: 18, saturation: -10, luminance: -4),
    ];
    final secondExpected = applyEditsToRgbaSync(
      originalFrame: frame,
      edits: edits,
      colorEdits: secondColorEdits,
      colorGradingEdits: gradingEdits,
    );
    final secondResult = await worker.process(
      edits: edits,
      colorEdits: secondColorEdits,
      colorGradingEdits: gradingEdits,
    );

    expect(secondResult.width, secondExpected.width);
    expect(secondResult.height, secondExpected.height);
    expect(secondResult.rgbaBytes, orderedEquals(secondExpected.rgbaBytes));
  });
}
