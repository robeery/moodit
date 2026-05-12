import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/color_operations.dart' as color_ops;
import 'package:licenta/model/color_edit.dart';

void main() {
  group('selective color operations', () {
    test('luminance-only edit preserves hue while changing luminance', () {
      final image = _singlePixelImage(34, 78, 220);
      final before = _hslFromBytes(_bytes(image));

      color_ops.applyAllColorEdits(image, [
        ColorEdit(range: ColorRange.blue, luminance: 60),
      ]);

      final afterBytes = _bytes(image);
      final after = _hslFromBytes(afterBytes);

      expect(after.luminance, greaterThan(before.luminance));
      expect(_hueDistance(before.hue, after.hue), lessThan(2.0));
      expect(afterBytes[3], 255);
    });

    test('hue-only edit changes hue without a luminance slider', () {
      final image = _singlePixelImage(34, 78, 220);
      final before = _hslFromBytes(_bytes(image));

      color_ops.applyAllColorEdits(image, [
        ColorEdit(range: ColorRange.blue, hue: 50),
      ]);

      final after = _hslFromBytes(_bytes(image));

      expect(_hueDistance(before.hue, after.hue), greaterThan(5.0));
      expect((after.luminance - before.luminance).abs(), lessThan(1.0));
    });

    test('cached hue/sat prep matches uncached output across slider changes', () {
      final cache = color_ops.SelectiveColorPrepCache();
      final firstEdits = [
        ColorEdit(range: ColorRange.blue, hue: 25, saturation: 20),
      ];
      final secondEdits = [
        ColorEdit(range: ColorRange.blue, hue: -20, saturation: 35),
      ];

      final firstUncached = _fixtureImage();
      final firstCached = _fixtureImage();
      color_ops.applyAllColorEdits(firstUncached, firstEdits);
      color_ops.applyAllColorEdits(
        firstCached,
        firstEdits,
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(_bytes(firstCached), orderedEquals(_bytes(firstUncached)));
      expect(cache.debugHueSatBuildCount, 1);
      expect(cache.debugHueSatMaskBuildCount, 1);

      final secondUncached = _fixtureImage();
      final secondCached = _fixtureImage();
      color_ops.applyAllColorEdits(secondUncached, secondEdits);
      color_ops.applyAllColorEdits(
        secondCached,
        secondEdits,
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(_bytes(secondCached), orderedEquals(_bytes(secondUncached)));
      expect(cache.debugHueSatBuildCount, 1);
      expect(cache.debugHueSatMaskBuildCount, 1);
    });

    test('cached hue/sat prep rebuilds for a different input key', () {
      final cache = color_ops.SelectiveColorPrepCache();
      final edits = [
        ColorEdit(range: ColorRange.blue, hue: 25, saturation: 20),
      ];

      color_ops.applyAllColorEdits(
        _fixtureImage(),
        edits,
        prepCache: cache,
        prepCacheKey: 'first-basic-input',
      );
      color_ops.applyAllColorEdits(
        _fixtureImage(),
        edits,
        prepCache: cache,
        prepCacheKey: 'second-basic-input',
      );

      expect(cache.debugHueSatBuildCount, 2);
      expect(cache.debugHueSatMaskBuildCount, 1);
    });

    test('cached hue/sat prep lazily builds one mask per touched range', () {
      final cache = color_ops.SelectiveColorPrepCache();

      color_ops.applyAllColorEdits(
        _fixtureImage(),
        [ColorEdit(range: ColorRange.blue, hue: 25)],
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(cache.debugHueSatBuildCount, 1);
      expect(cache.debugHueSatMaskBuildCount, 1);

      color_ops.applyAllColorEdits(
        _fixtureImage(),
        [ColorEdit(range: ColorRange.red, saturation: 20)],
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(cache.debugHueSatBuildCount, 1);
      expect(cache.debugHueSatMaskBuildCount, 2);
    });

    test('cached luminance prep matches uncached output across slider changes', () {
      final cache = color_ops.SelectiveColorPrepCache();
      final firstEdits = [
        ColorEdit(range: ColorRange.blue, luminance: 30),
      ];
      final secondEdits = [
        ColorEdit(range: ColorRange.blue, luminance: -25),
      ];

      final firstUncached = _fixtureImage();
      final firstCached = _fixtureImage();
      color_ops.applyAllColorEdits(firstUncached, firstEdits);
      color_ops.applyAllColorEdits(
        firstCached,
        firstEdits,
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(_bytes(firstCached), orderedEquals(_bytes(firstUncached)));
      expect(cache.debugLuminanceBuildCount, 1);
      expect(cache.debugLuminanceMaskBuildCount, 1);

      final secondUncached = _fixtureImage();
      final secondCached = _fixtureImage();
      color_ops.applyAllColorEdits(secondUncached, secondEdits);
      color_ops.applyAllColorEdits(
        secondCached,
        secondEdits,
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(_bytes(secondCached), orderedEquals(_bytes(secondUncached)));
      expect(cache.debugLuminanceBuildCount, 1);
      expect(cache.debugLuminanceMaskBuildCount, 1);
    });

    test('cached luminance prep lazily builds one mask per touched range', () {
      final cache = color_ops.SelectiveColorPrepCache();

      color_ops.applyAllColorEdits(
        _fixtureImage(),
        [ColorEdit(range: ColorRange.blue, luminance: 25)],
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(cache.debugLuminanceBuildCount, 1);
      expect(cache.debugLuminanceMaskBuildCount, 1);

      color_ops.applyAllColorEdits(
        _fixtureImage(),
        [ColorEdit(range: ColorRange.red, luminance: 20)],
        prepCache: cache,
        prepCacheKey: 'same-basic-input',
      );

      expect(cache.debugLuminanceBuildCount, 1);
      expect(cache.debugLuminanceMaskBuildCount, 2);
    });
  });
}

({double hue, double saturation, double luminance}) _hslFromBytes(
  Uint8List bytes,
) {
  final hsl = color_ops.rgbToHsl(
    bytes[0] / 255.0,
    bytes[1] / 255.0,
    bytes[2] / 255.0,
  );
  return (hue: hsl[0], saturation: hsl[1], luminance: hsl[2]);
}

img.Image _singlePixelImage(int r, int g, int b) {
  final image = img.Image(width: 1, height: 1, numChannels: 4);
  image.setPixelRgba(0, 0, r, g, b, 255);
  return image;
}

img.Image _fixtureImage({int width = 11, int height = 9}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (28 + x * 17 + y * 9).clamp(0, 255),
        (54 + x * 7 + y * 19).clamp(0, 255),
        (90 + x * 23 + y * 5).clamp(0, 255),
        255,
      );
    }
  }
  return image;
}

Uint8List _bytes(img.Image image) => image.toUint8List();

double _hueDistance(double a, double b) {
  final diff = (a - b).abs();
  return min(diff, 360 - diff);
}
