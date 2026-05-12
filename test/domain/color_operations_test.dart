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

Uint8List _bytes(img.Image image) => image.toUint8List();

double _hueDistance(double a, double b) {
  final diff = (a - b).abs();
  return min(diff, 360 - diff);
}
