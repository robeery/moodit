import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/domain/apply_edits.dart';
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
