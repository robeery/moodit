import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/apply_edits.dart';
import 'package:licenta/domain/color_grading_operations.dart' as grading_ops;
import 'package:licenta/domain/color_operations.dart' as color_ops;
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/rgba_image_frame.dart';

void main() {
  group('edit pipeline stage cache', () {
    test('reuses basic and selective stages across grading changes', () {
      final frame = frameFromImage(_fixtureImage());
      final cache = EditPipelineStageCache();
      final selectivePrepCache = color_ops.SelectiveColorPrepCache();
      final gradingPrepCache = grading_ops.ColorGradingPrepCache();
      final edits = _basicEdits(exposure: 25);
      final colorEdits = _selectiveEdits(blueHue: 18);
      final firstGrading = _gradingEdits(globalHue: 180, luminance: 10);
      final secondGrading = _gradingEdits(globalHue: 220, luminance: -8);

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: edits,
        colorEdits: colorEdits,
        colorGradingEdits: firstGrading,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-a',
        selectiveKey: 'selective-a',
      );

      expect(cache.debugAfterBasicBuildCount, 1);
      expect(cache.debugAfterSelectiveBuildCount, 1);

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: edits,
        colorEdits: colorEdits,
        colorGradingEdits: secondGrading,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-a',
        selectiveKey: 'selective-a',
      );

      expect(cache.debugAfterBasicBuildCount, 1);
      expect(cache.debugAfterSelectiveBuildCount, 1);
    });

    test('reuses basic stage and rebuilds selective when selective changes', () {
      final frame = frameFromImage(_fixtureImage());
      final cache = EditPipelineStageCache();
      final selectivePrepCache = color_ops.SelectiveColorPrepCache();
      final gradingPrepCache = grading_ops.ColorGradingPrepCache();
      final edits = _basicEdits(exposure: 25);
      final gradingEdits = _gradingEdits(globalHue: 180, luminance: 10);

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: edits,
        colorEdits: _selectiveEdits(blueHue: 18),
        colorGradingEdits: gradingEdits,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-a',
        selectiveKey: 'selective-a',
      );

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: edits,
        colorEdits: _selectiveEdits(blueHue: -16),
        colorGradingEdits: gradingEdits,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-a',
        selectiveKey: 'selective-b',
      );

      expect(cache.debugAfterBasicBuildCount, 1);
      expect(cache.debugAfterSelectiveBuildCount, 2);
    });

    test('rebuilds basic and selective stages when basic changes', () {
      final frame = frameFromImage(_fixtureImage());
      final cache = EditPipelineStageCache();
      final selectivePrepCache = color_ops.SelectiveColorPrepCache();
      final gradingPrepCache = grading_ops.ColorGradingPrepCache();
      final colorEdits = _selectiveEdits(blueHue: 18);
      final gradingEdits = _gradingEdits(globalHue: 180, luminance: 10);

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: _basicEdits(exposure: 25),
        colorEdits: colorEdits,
        colorGradingEdits: gradingEdits,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-a',
        selectiveKey: 'selective-a',
      );

      _expectCachedPipelineMatchesSync(
        frame: frame,
        edits: _basicEdits(exposure: -18),
        colorEdits: colorEdits,
        colorGradingEdits: gradingEdits,
        stageCache: cache,
        selectivePrepCache: selectivePrepCache,
        gradingPrepCache: gradingPrepCache,
        basicKey: 'basic-b',
        selectiveKey: 'selective-b',
      );

      expect(cache.debugAfterBasicBuildCount, 2);
      expect(cache.debugAfterSelectiveBuildCount, 2);
    });
  });
}

void _expectCachedPipelineMatchesSync({
  required RgbaImageFrame frame,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
  required EditPipelineStageCache stageCache,
  required color_ops.SelectiveColorPrepCache selectivePrepCache,
  required grading_ops.ColorGradingPrepCache gradingPrepCache,
  required String basicKey,
  required String selectiveKey,
}) {
  final expected = applyEditsToRgbaSync(
    originalFrame: frame,
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
  );
  final actual = applyEditsToRgbaWithStageCacheSync(
    originalFrame: frame,
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
    stageCache: stageCache,
    basicStageCacheKey: basicKey,
    selectiveStageCacheKey: selectiveKey,
    selectiveColorPrepCache: selectivePrepCache,
    selectiveColorPrepCacheKey: basicKey,
    colorGradingPrepCache: gradingPrepCache,
    colorGradingPrepCacheKey: selectiveKey,
  );

  expect(actual.width, expected.width);
  expect(actual.height, expected.height);
  expect(actual.rgbaBytes, orderedEquals(expected.rgbaBytes));
}

List<Edit> _basicEdits({required double exposure}) {
  return [
    Edit(type: OperationType.exposure, value: exposure),
    Edit(type: OperationType.contrast, value: 18),
    Edit(type: OperationType.vibrance, value: 20),
  ];
}

List<ColorEdit> _selectiveEdits({required double blueHue}) {
  return [
    ColorEdit(range: ColorRange.blue, hue: blueHue, saturation: 12, luminance: 4),
    ColorEdit(range: ColorRange.red, hue: -10, saturation: 8, luminance: -3),
  ];
}

List<ColorGradingEdit> _gradingEdits({
  required double globalHue,
  required double luminance,
}) {
  return [
    ColorGradingEdit(
      zone: ColorGradingZone.global,
      hue: globalHue,
      strength: 25,
      luminance: luminance,
    ),
    ColorGradingEdit(
      zone: ColorGradingZone.midtones,
      hue: 40,
      strength: 18,
      luminance: -4,
    ),
  ];
}

img.Image _fixtureImage({int width = 48, int height = 42}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (24 + x * 5 + y * 3).clamp(0, 255),
        (48 + x * 2 + y * 7).clamp(0, 255),
        (80 + x * 9 + y * 4).clamp(0, 255),
        255,
      );
    }
  }
  return image;
}
