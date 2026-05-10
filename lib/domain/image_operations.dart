import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'color_operations.dart' show HslValues, RgbValues, rgbToHslValues, hslToRgbValues;

//all of these should be improved/modified later in development
//by using better/more complex formulas and more parameters
//prototype operations

// Every pixel is stored as 4 consecutive bytes: R, G, B, A.
// So for a pixel starting at index i:
// data[i]     = red
// data[i + 1] = green
// data[i + 2] = blue
// data[i + 3] = alpha
const int _channelsPerPixel = 4;
const int _rgbChannelsPerPixel = 3;

Uint8List _rgbaBytes(img.Image image) => image.toUint8List();

int _clampByteFloor(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toInt();
}

int _clampByteRound(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.round();
}

int _clampByteInt(int value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value;
}

int _luminanceByte(int r, int g, int b) {
  return (77 * r + 150 * g + 29 * b + 128) >> 8;
}

double _clampChannelDouble(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toDouble();
}

Float64List _identityFloatLut() {
  final lut = Float64List(256);
  for (var i = 0; i < lut.length; i++) {
    lut[i] = i.toDouble();
  }
  return lut;
}

Uint8List _freezeFloatLut(Float64List lut) {
  final frozen = Uint8List(lut.length);
  for (var i = 0; i < lut.length; i++) {
    // We compose in floating point, then quantize once when the LUT is ready.
    frozen[i] = _clampByteRound(lut[i]);
  }
  return frozen;
}

void _applyRgbLuts(
  img.Image image, {
  required Uint8List lutR,
  required Uint8List lutG,
  required Uint8List lutB,
}) {
  final data = _rgbaBytes(image);

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // data[i] is red, data[i + 1] is green, data[i + 2] is blue.
    data[i] = lutR[data[i]];
    data[i + 1] = lutG[data[i + 1]];
    data[i + 2] = lutB[data[i + 2]];
  }
}

void _applySharedLut(img.Image image, Uint8List lut) {
  final data = _rgbaBytes(image);

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // The same per-channel LUT is applied to R, G, and B.
    data[i] = lut[data[i]];
    data[i + 1] = lut[data[i + 1]];
    data[i + 2] = lut[data[i + 2]];
  }
}

img.Image applyFusedColorBalanceOps(
  img.Image image, {
  required double exposure,
  required double warmth,
  required double tint,
  required double brightness,
}) {
  final hasAnyAdjustment =
      exposure.abs() > 0.001 ||
      warmth.abs() > 0.001 ||
      tint.abs() > 0.001 ||
      brightness.abs() > 0.001;
  if (!hasAnyAdjustment) return image;

  // These four ops are contiguous in the pipeline and each channel can be
  // described as "old byte -> new byte", so we compose them once here.
  final lutR = _identityFloatLut();
  final lutG = _identityFloatLut();
  final lutB = _identityFloatLut();

  if (exposure.abs() > 0.001) {
    final factor = pow(2.0, exposure).toDouble();
    for (var i = 0; i < 256; i++) {
      lutR[i] = _clampChannelDouble(lutR[i] * factor);
      lutG[i] = _clampChannelDouble(lutG[i] * factor);
      lutB[i] = _clampChannelDouble(lutB[i] * factor);
    }
  }

  if (warmth.abs() > 0.001) {
    final offset = warmth * 20;
    for (var i = 0; i < 256; i++) {
      // Warmth pushes red up and blue down. Green stays unchanged.
      lutR[i] = _clampChannelDouble(lutR[i] + offset);
      lutB[i] = _clampChannelDouble(lutB[i] - offset);
    }
  }

  if (tint.abs() > 0.001) {
    final offset = tint * 15;
    for (var i = 0; i < 256; i++) {
      // Positive tint adds magenta: R+, G-, B+.
      lutR[i] = _clampChannelDouble(lutR[i] + offset);
      lutG[i] = _clampChannelDouble(lutG[i] - offset * 1.5);
      lutB[i] = _clampChannelDouble(lutB[i] + offset);
    }
  }

  if (brightness.abs() > 0.001) {
    final gamma = pow(2.0, -brightness).toDouble();
    for (var i = 0; i < 256; i++) {
      lutR[i] = _clampChannelDouble(pow(lutR[i] / 255.0, gamma) * 255);
      lutG[i] = _clampChannelDouble(pow(lutG[i] / 255.0, gamma) * 255);
      lutB[i] = _clampChannelDouble(pow(lutB[i] / 255.0, gamma) * 255);
    }
  }

  _applyRgbLuts(
    image,
    lutR: _freezeFloatLut(lutR),
    lutG: _freezeFloatLut(lutG),
    lutB: _freezeFloatLut(lutB),
  );
  return image;
}

img.Image applyExposure(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  //EV stops: +1 = 2x light, -1 = 0.5x, like a real camera
  final factor = pow(2.0, value).toDouble();

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // data[i], data[i + 1], data[i + 2] are R, G, B for the current pixel.
    data[i] = _clampByteFloor(data[i] * factor);
    data[i + 1] = _clampByteFloor(data[i + 1] * factor);
    data[i + 2] = _clampByteFloor(data[i + 2] * factor);
  }

  return image;
}

img.Image applyBrightness(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  //gamma curve: <1 brightens, >1 darkens, preserves black and white
  final gamma = pow(2.0, -value).toDouble();

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Apply the same gamma curve separately to R, G, and B.
    data[i] = _clampByteFloor(pow(data[i] / 255.0, gamma) * 255);
    data[i + 1] =
        _clampByteFloor(pow(data[i + 1] / 255.0, gamma) * 255);
    data[i + 2] =
        _clampByteFloor(pow(data[i + 2] / 255.0, gamma) * 255);
  }

  return image;
}

img.Image applyHighlights(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final lut = _buildHighlightsLut(value);

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];
    final offset = _luminanceByte(r, g, b) << 8;

    data[i] = lut[offset + r];
    data[i + 1] = lut[offset + g];
    data[i + 2] = lut[offset + b];
  }

  return image;
}

Uint8List _buildHighlightsLut(double value) {
  final lut = Uint8List(256 * 256);
  final scaledValue = value * 0.7;

  for (var lumByte = 0; lumByte < 256; lumByte++) {
    final lum = lumByte / 255.0;
    // Smooth weight: 0 below midtones, ramps up through highlights
    final w = ((lum - 0.4) / 0.6).clamp(0.0, 1.0);
    final strength = w * w * scaledValue;
    final rowOffset = lumByte << 8;

    if (strength.abs() <= 0.001) {
      for (var channel = 0; channel < 256; channel++) {
        lut[rowOffset + channel] = channel;
      }
      continue;
    }

    for (var channel = 0; channel < 256; channel++) {
      lut[rowOffset + channel] =
          _clampByteFloor(channel + channel * strength);
    }
  }

  return lut;
}

img.Image applyShadows(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final lut = _buildShadowsLut(value);

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];
    final offset = _luminanceByte(r, g, b) << 8;

    data[i] = lut[offset + r];
    data[i + 1] = lut[offset + g];
    data[i + 2] = lut[offset + b];
  }

  return image;
}

Uint8List _buildShadowsLut(double value) {
  final lut = Uint8List(256 * 256);
  final scaledValue = value * 0.7;

  for (var lumByte = 0; lumByte < 256; lumByte++) {
    final lum = lumByte / 255.0;
    // Smooth weight: 0 above midtones, ramps up into shadows
    final w = ((0.6 - lum) / 0.6).clamp(0.0, 1.0);
    final strength = w * w * scaledValue;
    final rowOffset = lumByte << 8;

    if (strength.abs() <= 0.001) {
      for (var channel = 0; channel < 256; channel++) {
        lut[rowOffset + channel] = channel;
      }
      continue;
    }

    // Positive values lift shadows; negative values crush them
    final gamma = pow(2.0, -strength).toDouble();
    for (var channel = 0; channel < 256; channel++) {
      lut[rowOffset + channel] =
          _clampByteFloor(pow(channel / 255.0, gamma) * 255);
    }
  }

  return lut;
}

img.Image applyContrast(img.Image image, double value) {
  final contrast = value.clamp(-1.0, 1.0);
  if (contrast == 0.0) return image;

  final data = _rgbaBytes(image);

  //note to self:
  //maybe, in the future, implement a LUT to other functions as well

  //piecewise S-curve via power function, pre-baked into a LUT
  final gamma = pow(2.0, contrast);
  final lut = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    final t = i / 255.0;
    final adjusted = t < 0.5
        ? 0.5 * pow(2.0 * t, gamma)
        : 1.0 - 0.5 * pow(2.0 * (1.0 - t), gamma);
    lut[i] = _clampByteFloor(adjusted * 255);
  }

  //apply via luminance ratio to preserve color balance
  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Current pixel: R, G, B from the flat byte array
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];

    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    final lumInt = lum.round().clamp(0, 255);

    if (lumInt > 0) {
      final ratio = lut[lumInt] / lum;
      data[i] = _clampByteRound(r * ratio);
      data[i + 1] = _clampByteRound(g * ratio);
      data[i + 2] = _clampByteRound(b * ratio);
    }
  }

  return image;
}

img.Image applyWarmth(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final offset = value * 20;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Warmth shifts red up and blue down. Green stays unchanged
    data[i] = _clampByteFloor(data[i] + offset);
    data[i + 2] = _clampByteFloor(data[i + 2] - offset);
  }

  return image;
}

img.Image applyTint(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  //green-magenta axis: +tint = magenta (R+ G- B+), -tint = green (R- G+ B-)
  final offset = value * 15;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // R goes one way, G the opposite way, B follows R
    data[i] = _clampByteFloor(data[i] + offset);
    data[i + 1] = _clampByteFloor(data[i + 1] - offset * 1.5);
    data[i + 2] = _clampByteFloor(data[i + 2] + offset);
  }

  return image;
}

img.Image applySharpness(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final source = Uint8List.fromList(_rgbaBytes(image));
  final data = _rgbaBytes(image);
  final width = image.width;
  final height = image.height;
  final lastX = width - 1;
  final lastY = height - 1;
  final rowStride = width * _channelsPerPixel;
  final centerWeight = 1.0 + 4.0 * value;

  for (var y = 0; y < height; y++) {
    final rowStart = y * rowStride;
    final upOffset = y == 0 ? 0 : -rowStride;
    final downOffset = y == lastY ? 0 : rowStride;

    for (var x = 0, pixelIndex = rowStart;
        x < width;
        x++, pixelIndex += _channelsPerPixel) {
      final leftIndex = x == 0 ? pixelIndex : pixelIndex - _channelsPerPixel;
      final rightIndex =
          x == lastX ? pixelIndex : pixelIndex + _channelsPerPixel;
      final upIndex = pixelIndex + upOffset;
      final downIndex = pixelIndex + downOffset;

      final neighborR = source[leftIndex] +
          source[rightIndex] +
          source[upIndex] +
          source[downIndex];
      final neighborG = source[leftIndex + 1] +
          source[rightIndex + 1] +
          source[upIndex + 1] +
          source[downIndex + 1];
      final neighborB = source[leftIndex + 2] +
          source[rightIndex + 2] +
          source[upIndex + 2] +
          source[downIndex + 2];

      data[pixelIndex] = _clampByteFloor(
        source[pixelIndex] * centerWeight - neighborR * value,
      );
      data[pixelIndex + 1] = _clampByteFloor(
        source[pixelIndex + 1] * centerWeight - neighborG * value,
      );
      data[pixelIndex + 2] = _clampByteFloor(
        source[pixelIndex + 2] * centerWeight - neighborB * value,
      );
    }
  }

  return image;
}

img.Image applyDefinition(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  // This is very time consuming because it does a strong blur over the whole
  // image. I will deal with this later, and for now the pipeline skips the
  // definition stage temporarily in apply_edits.dart.
  // Larger radius separates local contrast from fine edges.
  final blurred = img.gaussianBlur(img.Image.from(image), radius: 20);
  final source = _rgbaBytes(image);
  final blurData = blurred.toUint8List();
  final strength = value * 1.2;

  for (var i = 0; i < source.length; i += _channelsPerPixel) {
    // source[...] is the original pixel, blurData[...] is the blurred version
    final origR = source[i];
    final origG = source[i + 1];
    final origB = source[i + 2];
    final blurR = blurData[i];
    final blurG = blurData[i + 1];
    final blurB = blurData[i + 2];

    //apply uniform luminance shift to all channels, preserving color
    final origLum = 0.299 * origR + 0.587 * origG + 0.114 * origB;
    final blurLum = 0.299 * blurR + 0.587 * blurG + 0.114 * blurB;
    final delta = (origLum - blurLum) * strength;

    source[i] = _clampByteFloor(origR + delta);
    source[i + 1] = _clampByteFloor(origG + delta);
    source[i + 2] = _clampByteFloor(origB + delta);
  }

  return image;
}

img.Image applySaturation(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final hsl = HslValues();
  final rgb = RgbValues();

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Convert current pixel from RGB bytes to HSL, then write RGB back
    final r = data[i] / 255.0;
    final g = data[i + 1] / 255.0;
    final b = data[i + 2] / 255.0;

    rgbToHslValues(r, g, b, hsl);
    //asymmetric: -100 fully desaturates, +100 gives a moderate boost
    final shift = value > 0 ? value * 40 : value * 100;
    final newS = (hsl.saturation + shift).clamp(0.0, 100.0).toDouble();
    hslToRgbValues(hsl.hue, newS, hsl.luminance, rgb);

    data[i] = _clampByteFloor(rgb.r);
    data[i + 1] = _clampByteFloor(rgb.g);
    data[i + 2] = _clampByteFloor(rgb.b);
  }

  return image;
}

img.Image applyVibrance(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Read normalized RGB from the current pixel in the flat byte buffer
    final r = data[i] / 255.0;
    final g = data[i + 1] / 255.0;
    final b = data[i + 2] / 255.0;

    final maxC = max(r, max(g, b));
    final minC = min(r, min(g, b));
    final s = maxC == 0 ? 0.0 : (maxC - minC) / maxC;

    //boost inversely proportional to existing saturation
    final factor = 1.0 + value * (1.0 - s);

    final mid = (r + g + b) / 3.0;
    final nr = (mid + (r - mid) * factor).clamp(0.0, 1.0);
    final ng = (mid + (g - mid) * factor).clamp(0.0, 1.0);
    final nb = (mid + (b - mid) * factor).clamp(0.0, 1.0);

    data[i] = _clampByteFloor(nr * 255);
    data[i + 1] = _clampByteFloor(ng * 255);
    data[i + 2] = _clampByteFloor(nb * 255);
  }

  return image;
}

img.Image applyBlackpoint(img.Image image, double value) {
  if (value <= 0.001) return image;

  final threshold = value * 60; // max threshold ~60, not 255
  final scale = 255 / (255 - threshold);
  final lut = Uint8List(256);

  for (var channel = 0; channel < 256; channel++) {
    if (channel <= threshold) {
      lut[channel] = 0;
    } else {
      lut[channel] = _clampByteFloor((channel - threshold) * scale);
    }
  }

  _applySharedLut(image, lut);
  return image;
}

img.Image applyVignette(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final width = image.width;
  final height = image.height;
  final centerX = width / 2;
  final centerY = height / 2;
  final invMaxDistSquared = 1.0 / (centerX * centerX + centerY * centerY);
  final rowStride = width * _channelsPerPixel;
  final falloffScale = value * invMaxDistSquared;
  final columnFalloff = Float64List(width);
  for (var x = 0; x < width; x++) {
    final dx = x - centerX;
    columnFalloff[x] = dx * dx * falloffScale;
  }

  for (var y = 0; y < height; y++) {
    final dy = y - centerY;
    final rowFalloff = dy * dy * falloffScale;
    final rowStart = y * rowStride;
    for (var x = 0, pixelIndex = rowStart;
        x < width;
        x++, pixelIndex += _channelsPerPixel) {
      final factor = 1.0 - rowFalloff - columnFalloff[x];

      data[pixelIndex] = _clampByteFloor(data[pixelIndex] * factor);
      data[pixelIndex + 1] =
          _clampByteFloor(data[pixelIndex + 1] * factor);
      data[pixelIndex + 2] =
          _clampByteFloor(data[pixelIndex + 2] * factor);
    }
  }

  return image;
}

void _applySeparableBoxBlurRgbGeneral(img.Image image, int radius) {
  if (radius <= 0) return;

  final data = _rgbaBytes(image);
  final source = Uint8List.fromList(data);
  final horizontal = Uint8List(data.length);
  final width = image.width;
  final height = image.height;
  final rowStride = width * _channelsPerPixel;
  final maxX = width - 1;
  final maxY = height - 1;

  for (var y = 0; y < height; y++) {
    final rowStart = y * rowStride;
    var left = 0;
    var right = -1;
    var sumR = 0;
    var sumG = 0;
    var sumB = 0;

    for (var x = 0; x < width; x++) {
      final nextRight = min(maxX, x + radius);
      while (right < nextRight) {
        right++;
        final offset = rowStart + right * _channelsPerPixel;
        sumR += source[offset];
        sumG += source[offset + 1];
        sumB += source[offset + 2];
      }

      final nextLeft = max(0, x - radius);
      while (left < nextLeft) {
        final offset = rowStart + left * _channelsPerPixel;
        sumR -= source[offset];
        sumG -= source[offset + 1];
        sumB -= source[offset + 2];
        left++;
      }

      final count = right - left + 1;
      final outOffset = rowStart + x * _channelsPerPixel;
      horizontal[outOffset] = (sumR + count ~/ 2) ~/ count;
      horizontal[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      horizontal[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }

  for (var x = 0; x < width; x++) {
    var top = 0;
    var bottom = -1;
    var sumR = 0;
    var sumG = 0;
    var sumB = 0;

    for (var y = 0; y < height; y++) {
      final nextBottom = min(maxY, y + radius);
      while (bottom < nextBottom) {
        bottom++;
        final offset = bottom * rowStride + x * _channelsPerPixel;
        sumR += horizontal[offset];
        sumG += horizontal[offset + 1];
        sumB += horizontal[offset + 2];
      }

      final nextTop = max(0, y - radius);
      while (top < nextTop) {
        final offset = top * rowStride + x * _channelsPerPixel;
        sumR -= horizontal[offset];
        sumG -= horizontal[offset + 1];
        sumB -= horizontal[offset + 2];
        top++;
      }

      final count = bottom - top + 1;
      final outOffset = y * rowStride + x * _channelsPerPixel;
      data[outOffset] = (sumR + count ~/ 2) ~/ count;
      data[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      data[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }
}

void _applySmallRadiusBoxBlurRgb(img.Image image, int radius) {
  final data = _rgbaBytes(image);
  final source = Uint8List.fromList(data);
  final width = image.width;
  final height = image.height;
  final maxX = width - 1;
  final maxY = height - 1;
  final rowStride = width * _channelsPerPixel;
  final rgbRowStride = width * _rgbChannelsPerPixel;
  final kernelSize = radius * 2 + 1;
  final horizontal = Uint8List(width * height * _rgbChannelsPerPixel);

  for (var y = 0; y < height; y++) {
    final sourceRowStart = y * rowStride;
    final rgbRowStart = y * rgbRowStride;
    var sumR = 0;
    var sumG = 0;
    var sumB = 0;

    for (var x = 0; x <= radius; x++) {
      final offset = sourceRowStart + x * _channelsPerPixel;
      sumR += source[offset];
      sumG += source[offset + 1];
      sumB += source[offset + 2];
    }

    var outOffset = rgbRowStart;
    var count = radius + 1;
    horizontal[outOffset] = (sumR + count ~/ 2) ~/ count;
    horizontal[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
    horizontal[outOffset + 2] = (sumB + count ~/ 2) ~/ count;

    for (var x = 1; x <= radius; x++) {
      final addOffset = sourceRowStart + (x + radius) * _channelsPerPixel;
      sumR += source[addOffset];
      sumG += source[addOffset + 1];
      sumB += source[addOffset + 2];

      count = radius + x + 1;
      outOffset += _rgbChannelsPerPixel;
      horizontal[outOffset] = (sumR + count ~/ 2) ~/ count;
      horizontal[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      horizontal[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }

    for (var x = radius + 1; x <= maxX - radius; x++) {
      final addOffset = sourceRowStart + (x + radius) * _channelsPerPixel;
      final removeOffset =
          sourceRowStart + (x - radius - 1) * _channelsPerPixel;
      sumR += source[addOffset] - source[removeOffset];
      sumG += source[addOffset + 1] - source[removeOffset + 1];
      sumB += source[addOffset + 2] - source[removeOffset + 2];

      outOffset += _rgbChannelsPerPixel;
      horizontal[outOffset] = (sumR + kernelSize ~/ 2) ~/ kernelSize;
      horizontal[outOffset + 1] = (sumG + kernelSize ~/ 2) ~/ kernelSize;
      horizontal[outOffset + 2] = (sumB + kernelSize ~/ 2) ~/ kernelSize;
    }

    for (var x = maxX - radius + 1; x <= maxX; x++) {
      final removeOffset =
          sourceRowStart + (x - radius - 1) * _channelsPerPixel;
      sumR -= source[removeOffset];
      sumG -= source[removeOffset + 1];
      sumB -= source[removeOffset + 2];

      count = maxX - x + radius + 1;
      outOffset += _rgbChannelsPerPixel;
      horizontal[outOffset] = (sumR + count ~/ 2) ~/ count;
      horizontal[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      horizontal[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }

  for (var x = 0; x < width; x++) {
    final rgbColumnOffset = x * _rgbChannelsPerPixel;
    final dataColumnOffset = x * _channelsPerPixel;
    var sumR = 0;
    var sumG = 0;
    var sumB = 0;

    for (var y = 0; y <= radius; y++) {
      final offset = y * rgbRowStride + rgbColumnOffset;
      sumR += horizontal[offset];
      sumG += horizontal[offset + 1];
      sumB += horizontal[offset + 2];
    }

    var count = radius + 1;
    var outOffset = dataColumnOffset;
    data[outOffset] = (sumR + count ~/ 2) ~/ count;
    data[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
    data[outOffset + 2] = (sumB + count ~/ 2) ~/ count;

    for (var y = 1; y <= radius; y++) {
      final addOffset = (y + radius) * rgbRowStride + rgbColumnOffset;
      sumR += horizontal[addOffset];
      sumG += horizontal[addOffset + 1];
      sumB += horizontal[addOffset + 2];

      count = radius + y + 1;
      outOffset += rowStride;
      data[outOffset] = (sumR + count ~/ 2) ~/ count;
      data[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      data[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }

    for (var y = radius + 1; y <= maxY - radius; y++) {
      final addOffset = (y + radius) * rgbRowStride + rgbColumnOffset;
      final removeOffset =
          (y - radius - 1) * rgbRowStride + rgbColumnOffset;
      sumR += horizontal[addOffset] - horizontal[removeOffset];
      sumG += horizontal[addOffset + 1] - horizontal[removeOffset + 1];
      sumB += horizontal[addOffset + 2] - horizontal[removeOffset + 2];

      outOffset += rowStride;
      data[outOffset] = (sumR + kernelSize ~/ 2) ~/ kernelSize;
      data[outOffset + 1] = (sumG + kernelSize ~/ 2) ~/ kernelSize;
      data[outOffset + 2] = (sumB + kernelSize ~/ 2) ~/ kernelSize;
    }

    for (var y = maxY - radius + 1; y <= maxY; y++) {
      final removeOffset =
          (y - radius - 1) * rgbRowStride + rgbColumnOffset;
      sumR -= horizontal[removeOffset];
      sumG -= horizontal[removeOffset + 1];
      sumB -= horizontal[removeOffset + 2];

      count = maxY - y + radius + 1;
      outOffset += rowStride;
      data[outOffset] = (sumR + count ~/ 2) ~/ count;
      data[outOffset + 1] = (sumG + count ~/ 2) ~/ count;
      data[outOffset + 2] = (sumB + count ~/ 2) ~/ count;
    }
  }
}

void _applySeparableBoxBlurRgb(img.Image image, int radius) {
  if (radius <= 0) return;
  if (radius <= 3 &&
      image.width > radius * 2 &&
      image.height > radius * 2) {
    _applySmallRadiusBoxBlurRgb(image, radius);
    return;
  }

  _applySeparableBoxBlurRgbGeneral(image, radius);
}

//fast blur operation
img.Image applyBlur(img.Image image, double value) {
  if (value <= 0.001) return image;

  final radius = (value * 3).round().clamp(1, 3).toInt();
  _applySeparableBoxBlurRgb(image, radius);
  return image;
}

img.Image applyGrain(img.Image image, double value) {
  if (value <= 0.001) return image;

  final data = _rgbaBytes(image);
  var amplitude = (value * 80).round();
  if (amplitude < 1) amplitude = 1;
  final noiseRange = amplitude * 2 + 1;
  var noiseState = 42;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    noiseState = _nextGrainNoiseState(noiseState);
    // Grain adds the same monochrome noise amount to R, G, and B
    final noise = ((((noiseState >> 16) & 0xffff) * noiseRange) >> 16) -
        amplitude;

    data[i] = _clampByteInt(data[i] + noise);
    data[i + 1] = _clampByteInt(data[i + 1] + noise);
    data[i + 2] = _clampByteInt(data[i + 2] + noise);
  }

  return image;
}

int _nextGrainNoiseState(int state) {
  state ^= (state << 13) & 0xffffffff;
  state ^= state >> 17;
  state ^= (state << 5) & 0xffffffff;
  return state & 0xffffffff;
}

img.Image applyFade(img.Image image, double value) {
  if (value <= 0.001) return image;

  //fade lifts shadows and slightly desaturates, like a film wash
  final strength = value * 0.4;
  final lift = strength * 80;
  final lut = Uint8List(256);

  for (var channel = 0; channel < 256; channel++) {
    lut[channel] = _clampByteFloor(channel * (1 - strength) + lift);
  }

  _applySharedLut(image, lut);
  return image;
}
