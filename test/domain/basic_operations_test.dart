import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/apply_edits.dart';
import 'package:licenta/domain/color_operations.dart' as color_ops;
import 'package:licenta/domain/image_operations.dart';
import 'package:licenta/domain/parse_edits_json.dart';
import 'package:licenta/model/edit.dart';

typedef _OperationApplier = img.Image Function(img.Image image, double value);

class _OperationCase {
  const _OperationCase(this.type, this.apply, this.activeValue);

  final OperationType type;
  final _OperationApplier apply;
  final double activeValue;
}

final _operationCases = [
  _OperationCase(OperationType.exposure, applyExposure, 0.5),
  _OperationCase(OperationType.warmth, applyWarmth, 0.8),
  _OperationCase(OperationType.tint, applyTint, 0.8),
  _OperationCase(OperationType.brightness, applyBrightness, 0.4),
  _OperationCase(OperationType.highlights, applyHighlights, 0.8),
  _OperationCase(OperationType.shadows, applyShadows, 0.8),
  _OperationCase(OperationType.contrast, applyContrast, 0.6),
  _OperationCase(OperationType.blackpoint, applyBlackpoint, 0.5),
  _OperationCase(OperationType.saturation, applySaturation, 0.7),
  _OperationCase(OperationType.vibrance, applyVibrance, 0.7),
  _OperationCase(OperationType.definition, applyDefinition, 0.5),
  _OperationCase(OperationType.sharpness, applySharpness, 0.5),
  _OperationCase(OperationType.vignette, applyVignette, 0.7),
  _OperationCase(OperationType.blur, applyBlur, 0.7),
  _OperationCase(OperationType.grain, applyGrain, 0.5),
  _OperationCase(OperationType.fade, applyFade, 0.5),
];

void main() {
  group('basic image operations', () {
    for (final operation in _operationCases) {
      test('${operation.type.name} is a no-op at zero', () {
        final image = _fixtureImage();
        final before = _bytes(image);

        operation.apply(image, 0);

        expect(_bytes(image), orderedEquals(before));
      });

      test('${operation.type.name} changes RGB and preserves alpha', () {
        final image = operation.type == OperationType.definition
            ? _fixtureImage(width: 64, height: 64)
            : _fixtureImage();
        final before = _bytes(image);

        operation.apply(image, operation.activeValue);
        final after = _bytes(image);

        expect(_rgbChanged(before, after), isTrue);
        expect(_alphaPreserved(before, after), isTrue);
      });
    }
  });

  test('basic pipeline accepts every operation type', () {
    final originalFrame = frameFromImage(_fixtureImage());

    for (final type in OperationType.values) {
      final result = applyEditsToRgbaSync(
        originalFrame: originalFrame,
        edits: [Edit(type: type, value: type.minValue == 0 ? 50 : 30)],
        colorEdits: const [],
        colorGradingEdits: const [],
      );

      expect(result.width, originalFrame.width, reason: type.name);
      expect(result.height, originalFrame.height, reason: type.name);
      expect(result.rgbaBytes.length, originalFrame.rgbaBytes.length,
          reason: type.name);
    }
  });

  test('blur operation round-trips through JSON names', () {
    final encoded = Edit(type: OperationType.blur, value: 50).toJson();
    expect(encoded['type'], 'blur');

    final result = parseEditsJson(
      '{"message":"Added blur","edits":[{"type":"blur","value":50}]}',
    );

    expect(result.error, isNull);
    expect(result.edits!.edits.single.type, OperationType.blur);
    expect(result.edits!.edits.single.value, 50);
  });

  test('blur matches edge-averaged separable reference', () {
    const cases = [
      (value: 0.2, radius: 1),
      (value: 0.5, radius: 2),
      (value: 1.0, radius: 3),
    ];

    for (final c in cases) {
      final image = _fixtureImage(width: 9, height: 8);
      final expected = _referenceBlurBytes(image, c.radius);

      applyBlur(image, c.value);

      expect(_bytes(image), orderedEquals(expected), reason: 'radius ${c.radius}');
    }
  });

  test('grain is deterministic for the same input and value', () {
    final first = _fixtureImage(width: 13, height: 11);
    final second = _fixtureImage(width: 13, height: 11);

    applyGrain(first, 0.5);
    applyGrain(second, 0.5);

    expect(_bytes(first), orderedEquals(_bytes(second)));
  });

  test('sharpness keeps a flat image unchanged', () {
    final image = _solidImage(width: 11, height: 9, r: 90, g: 120, b: 150);
    final before = _bytes(image);

    applySharpness(image, 0.8);

    expect(_bytes(image), orderedEquals(before));
  });

  test('vignette leaves the center unchanged and darkens edges', () {
    final image = _solidImage(width: 10, height: 10, r: 120, g: 130, b: 140);

    applyVignette(image, 0.8);
    final bytes = _bytes(image);

    final centerIndex = (5 * 10 + 5) * 4;
    expect(bytes[centerIndex], 120);
    expect(bytes[centerIndex + 1], 130);
    expect(bytes[centerIndex + 2], 140);

    expect(bytes[0], lessThan(120));
    expect(bytes[1], lessThan(130));
    expect(bytes[2], lessThan(140));
  });

  test('shadows lifts dark pixels and leaves bright pixels alone', () {
    final image = img.Image(width: 2, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 50, 50, 50, 255);
    image.setPixelRgba(1, 0, 220, 220, 220, 255);

    applyShadows(image, 0.8);
    final bytes = _bytes(image);

    expect(bytes[0], greaterThan(50));
    expect(bytes[1], greaterThan(50));
    expect(bytes[2], greaterThan(50));
    expect(bytes[4], 220);
    expect(bytes[5], 220);
    expect(bytes[6], 220);
  });

  test('highlights boosts bright pixels and leaves dark pixels alone', () {
    final image = img.Image(width: 2, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 50, 50, 50, 255);
    image.setPixelRgba(1, 0, 180, 180, 180, 255);

    applyHighlights(image, 0.8);
    final bytes = _bytes(image);

    expect(bytes[0], 50);
    expect(bytes[1], 50);
    expect(bytes[2], 50);
    expect(bytes[4], greaterThan(180));
    expect(bytes[5], greaterThan(180));
    expect(bytes[6], greaterThan(180));
  });

  test('contrast darkens dark pixels and brightens bright pixels', () {
    final image = img.Image(width: 2, height: 1, numChannels: 4);
    image.setPixelRgba(0, 0, 70, 70, 70, 255);
    image.setPixelRgba(1, 0, 190, 190, 190, 255);

    applyContrast(image, 0.8);
    final bytes = _bytes(image);

    expect(bytes[0], lessThan(70));
    expect(bytes[1], lessThan(70));
    expect(bytes[2], lessThan(70));
    expect(bytes[4], greaterThan(190));
    expect(bytes[5], greaterThan(190));
    expect(bytes[6], greaterThan(190));
  });

  test('saturation stays close to the HSL reference formula', () {
    final image = _fixtureImage(width: 10, height: 7);
    final expected = _referenceSaturationBytes(image, 0.7);

    applySaturation(image, 0.7);

    expect(_bytesClose(_bytes(image), expected, tolerance: 1), isTrue);
  });

  test('vibrance stays close to the reference formula', () {
    final image = _fixtureImage(width: 10, height: 7);
    final expected = _referenceVibranceBytes(image, 0.7);

    applyVibrance(image, 0.7);

    expect(_bytesClose(_bytes(image), expected, tolerance: 1), isTrue);
  });
}

img.Image _fixtureImage({int width = 9, int height = 7}) {
  final image = img.Image(width: width, height: height, numChannels: 4);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final r = _byte(18 + x * 24 + y * 9);
      final g = _byte(36 + x * 7 + y * 29);
      final b = _byte(54 + x * 17 + y * 13);
      final a = _byte(128 + ((x + y) % 4) * 31);
      image.setPixelRgba(x, y, r, g, b, a);
    }
  }

  return image;
}

int _byte(int value) => value.clamp(0, 255).toInt();

Uint8List _bytes(img.Image image) => Uint8List.fromList(image.toUint8List());

bool _rgbChanged(Uint8List before, Uint8List after) {
  for (var i = 0; i < before.length; i += 4) {
    if (before[i] != after[i] ||
        before[i + 1] != after[i + 1] ||
        before[i + 2] != after[i + 2]) {
      return true;
    }
  }
  return false;
}

bool _alphaPreserved(Uint8List before, Uint8List after) {
  for (var i = 3; i < before.length; i += 4) {
    if (before[i] != after[i]) return false;
  }
  return true;
}

Uint8List _referenceBlurBytes(img.Image image, int radius) {
  final data = _bytes(image);
  final width = image.width;
  final height = image.height;
  final horizontal = Uint8List(data.length);
  final out = Uint8List.fromList(data);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final startX = x - radius < 0 ? 0 : x - radius;
      final endX = x + radius >= width ? width - 1 : x + radius;
      final count = endX - startX + 1;
      var sumR = 0;
      var sumG = 0;
      var sumB = 0;

      for (var sx = startX; sx <= endX; sx++) {
        final offset = (y * width + sx) * 4;
        sumR += data[offset];
        sumG += data[offset + 1];
        sumB += data[offset + 2];
      }

      final outOffset = (y * width + x) * 4;
      horizontal[outOffset] = (sumR + count ~/ 2) ~/ count;
      horizontal[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      horizontal[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }

  for (var y = 0; y < height; y++) {
    final startY = y - radius < 0 ? 0 : y - radius;
    final endY = y + radius >= height ? height - 1 : y + radius;
    final count = endY - startY + 1;
    for (var x = 0; x < width; x++) {
      var sumR = 0;
      var sumG = 0;
      var sumB = 0;

      for (var sy = startY; sy <= endY; sy++) {
        final offset = (sy * width + x) * 4;
        sumR += horizontal[offset];
        sumG += horizontal[offset + 1];
        sumB += horizontal[offset + 2];
      }

      final outOffset = (y * width + x) * 4;
      out[outOffset] = (sumR + count ~/ 2) ~/ count;
      out[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      out[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }

  return out;
}

Uint8List _referenceSaturationBytes(img.Image image, double value) {
  final data = _bytes(image);
  final hsl = color_ops.HslValues();
  final rgb = color_ops.RgbValues();
  final shift = value > 0 ? value * 40 : value * 100;

  for (var i = 0; i < data.length; i += 4) {
    color_ops.rgbToHslValues(
      data[i] / 255.0,
      data[i + 1] / 255.0,
      data[i + 2] / 255.0,
      hsl,
    );
    final newS = (hsl.saturation + shift).clamp(0.0, 100.0).toDouble();
    color_ops.hslToRgbValues(hsl.hue, newS, hsl.luminance, rgb);

    data[i] = _byte(rgb.r.toInt());
    data[i + 1] = _byte(rgb.g.toInt());
    data[i + 2] = _byte(rgb.b.toInt());
  }

  return data;
}

Uint8List _referenceVibranceBytes(img.Image image, double value) {
  final data = _bytes(image);

  for (var i = 0; i < data.length; i += 4) {
    final r = data[i] / 255.0;
    final g = data[i + 1] / 255.0;
    final b = data[i + 2] / 255.0;

    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final s = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
    final factor = 1.0 + value * (1.0 - s);
    final mid = (r + g + b) / 3.0;

    data[i] = _byte(((mid + (r - mid) * factor) * 255).toInt());
    data[i + 1] = _byte(((mid + (g - mid) * factor) * 255).toInt());
    data[i + 2] = _byte(((mid + (b - mid) * factor) * 255).toInt());
  }

  return data;
}

bool _bytesClose(Uint8List actual, Uint8List expected, {required int tolerance}) {
  if (actual.length != expected.length) return false;
  for (var i = 0; i < actual.length; i++) {
    if ((actual[i] - expected[i]).abs() > tolerance) return false;
  }
  return true;
}

img.Image _solidImage({
  required int width,
  required int height,
  required int r,
  required int g,
  required int b,
  int a = 255,
}) {
  final image = img.Image(width: width, height: height, numChannels: 4);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, r, g, b, a);
    }
  }

  return image;
}
