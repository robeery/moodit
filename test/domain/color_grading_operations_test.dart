import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/color_grading_operations.dart';
import 'package:licenta/model/color_grading_edit.dart';

void main() {
  group('color grading operations', () {
    test('empty grading edit is a no-op', () {
      final image = _fixtureImage();
      final before = _bytes(image);

      applyColorGrading(image, [ColorGradingEdit(zone: ColorGradingZone.global)]);

      expect(_bytes(image), orderedEquals(before));
    });

    test('shadow luminance edit lifts dark pixels and leaves highlights alone', () {
      final image = img.Image(width: 2, height: 1, numChannels: 4);
      image.setPixelRgba(0, 0, 32, 32, 32, 255);
      image.setPixelRgba(1, 0, 230, 230, 230, 255);

      applyColorGrading(image, [
        ColorGradingEdit(zone: ColorGradingZone.shadows, luminance: 60),
      ]);
      final bytes = _bytes(image);

      expect(bytes[0], greaterThan(32));
      expect(bytes[1], greaterThan(32));
      expect(bytes[2], greaterThan(32));
      expect(bytes[4], 230);
      expect(bytes[5], 230);
      expect(bytes[6], 230);
      expect(bytes[3], 255);
      expect(bytes[7], 255);
    });

    test('highlight luminance edit lifts bright pixels and leaves shadows alone', () {
      final image = img.Image(width: 2, height: 1, numChannels: 4);
      image.setPixelRgba(0, 0, 32, 32, 32, 255);
      image.setPixelRgba(1, 0, 230, 230, 230, 255);

      applyColorGrading(image, [
        ColorGradingEdit(zone: ColorGradingZone.highlights, luminance: 60),
      ]);
      final bytes = _bytes(image);

      expect(bytes[0], 32);
      expect(bytes[1], 32);
      expect(bytes[2], 32);
      expect(bytes[4], greaterThan(230));
      expect(bytes[5], greaterThan(230));
      expect(bytes[6], greaterThan(230));
      expect(bytes[3], 255);
      expect(bytes[7], 255);
    });

    test('midtone luminance edit favors mid gray over extremes', () {
      final image = img.Image(width: 3, height: 1, numChannels: 4);
      image.setPixelRgba(0, 0, 32, 32, 32, 255);
      image.setPixelRgba(1, 0, 128, 128, 128, 255);
      image.setPixelRgba(2, 0, 230, 230, 230, 255);

      applyColorGrading(image, [
        ColorGradingEdit(zone: ColorGradingZone.midtones, luminance: 60),
      ]);
      final bytes = _bytes(image);

      expect(bytes[0], 32);
      expect(bytes[4], greaterThan(128));
      expect(bytes[8], 230);
      expect(bytes[3], 255);
      expect(bytes[7], 255);
      expect(bytes[11], 255);
    });

    test('cached prep matches uncached output across grading slider changes', () {
      final cache = ColorGradingPrepCache();
      final firstEdits = [
        ColorGradingEdit(
          zone: ColorGradingZone.global,
          hue: 180,
          strength: 35,
          luminance: 10,
        ),
      ];
      final secondEdits = [
        ColorGradingEdit(
          zone: ColorGradingZone.shadows,
          hue: 220,
          strength: 30,
          luminance: -12,
        ),
        ColorGradingEdit(
          zone: ColorGradingZone.highlights,
          hue: 40,
          strength: 25,
          luminance: 15,
        ),
      ];

      final firstUncached = _fixtureImage(width: 15, height: 13);
      final firstCached = _fixtureImage(width: 15, height: 13);
      applyColorGrading(firstUncached, firstEdits);
      applyColorGrading(
        firstCached,
        firstEdits,
        prepCache: cache,
        prepCacheKey: 'same-grading-input',
      );

      expect(_bytes(firstCached), orderedEquals(_bytes(firstUncached)));
      expect(cache.debugBuildCount, 1);

      final secondUncached = _fixtureImage(width: 15, height: 13);
      final secondCached = _fixtureImage(width: 15, height: 13);
      applyColorGrading(secondUncached, secondEdits);
      applyColorGrading(
        secondCached,
        secondEdits,
        prepCache: cache,
        prepCacheKey: 'same-grading-input',
      );

      expect(_bytes(secondCached), orderedEquals(_bytes(secondUncached)));
      expect(cache.debugBuildCount, 1);
    });

    test('cached prep rebuilds for a different input key', () {
      final cache = ColorGradingPrepCache();
      final edits = [
        ColorGradingEdit(
          zone: ColorGradingZone.global,
          hue: 180,
          strength: 35,
          luminance: 10,
        ),
      ];

      applyColorGrading(
        _fixtureImage(),
        edits,
        prepCache: cache,
        prepCacheKey: 'first-grading-input',
      );
      applyColorGrading(
        _fixtureImage(),
        edits,
        prepCache: cache,
        prepCacheKey: 'second-grading-input',
      );

      expect(cache.debugBuildCount, 2);
    });
  });
}

img.Image _fixtureImage({int width = 5, int height = 4}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (35 + x * 30 + y * 11).clamp(0, 255),
        (55 + x * 12 + y * 25).clamp(0, 255),
        (75 + x * 18 + y * 7).clamp(0, 255),
        255,
      );
    }
  }
  return image;
}

Uint8List _bytes(img.Image image) => image.toUint8List();
