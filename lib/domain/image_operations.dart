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

int _clampCoord(int value, int maxValue) {
  if (value <= 0) return 0;
  if (value >= maxValue) return maxValue;
  return value;
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
  final scaledValue = value * 0.7;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Read current pixel channels from the raw RGBA buffer
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];
    final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

    //smooth weight: 0 below midtones, ramps up through highlights
    final w = ((lum - 0.4) / 0.6).clamp(0.0, 1.0);
    //squared for softer onset, stronger at the top
    final strength = w * w * scaledValue;

    data[i] = _clampByteFloor(r + r * strength);
    data[i + 1] = _clampByteFloor(g + g * strength);
    data[i + 2] = _clampByteFloor(b + b * strength);
  }

  return image;
}

img.Image applyShadows(img.Image image, double value) {
  if (value.abs() <= 0.001) return image;

  final data = _rgbaBytes(image);
  final scaledValue = value * 0.7;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Read current pixel channels from the raw RGBA buffer
    final r = data[i];
    final g = data[i + 1];
    final b = data[i + 2];
    final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

    //smooth weight: 0 above midtones, ramps up into shadows
    final w = ((0.6 - lum) / 0.6).clamp(0.0, 1.0);
    final strength = w * w * scaledValue;

    //positive: lift shadows using gamma curve (like brightness)
    //negative: crush shadows using gamma curve
    final gamma = pow(2.0, -strength).toDouble();
    data[i] = _clampByteFloor(pow(r / 255.0, gamma) * 255);
    data[i + 1] = _clampByteFloor(pow(g / 255.0, gamma) * 255);
    data[i + 2] = _clampByteFloor(pow(b / 255.0, gamma) * 255);
  }

  return image;
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
  final maxX = width - 1;
  final maxY = height - 1;

  final kernel = [
    0.0, -value, 0.0,
    -value, 1.0 + 4 * value, -value,
    0.0, -value, 0.0,
  ];

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      double r = 0;
      double g = 0;
      double b = 0;

      for (var ky = -1, kernelIndex = 0; ky <= 1; ky++) {
        final ny = _clampCoord(y + ky, maxY);
        for (var kx = -1; kx <= 1; kx++, kernelIndex++) {
          final nx = _clampCoord(x + kx, maxX);
          // sampleIndex points to the R byte of neighbor pixel (nx, ny)
          final sampleIndex =
              (ny * width + nx) * _channelsPerPixel;
          final weight = kernel[kernelIndex];
          r += source[sampleIndex] * weight;
          g += source[sampleIndex + 1] * weight;
          b += source[sampleIndex + 2] * weight;
        }
      }

      final pixelIndex = (y * width + x) * _channelsPerPixel;
      // pixelIndex points to the R byte of the output pixel (x, y)
      data[pixelIndex] = _clampByteFloor(r);
      data[pixelIndex + 1] = _clampByteFloor(g);
      data[pixelIndex + 2] = _clampByteFloor(b);
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
  final maxDist = sqrt(centerX * centerX + centerY * centerY);

  for (var y = 0; y < height; y++) {
    final dy = y - centerY;
    for (var x = 0; x < width; x++) {
      // pixelIndex points to the R byte of pixel (x, y)
      final pixelIndex = (y * width + x) * _channelsPerPixel;

      final dx = x - centerX;
      final dist = sqrt(dx * dx + dy * dy);

      final d = dist / maxDist;
      final factor = 1.0 - (value * d * d);

      data[pixelIndex] = _clampByteFloor(data[pixelIndex] * factor);
      data[pixelIndex + 1] =
          _clampByteFloor(data[pixelIndex + 1] * factor);
      data[pixelIndex + 2] =
          _clampByteFloor(data[pixelIndex + 2] * factor);
    }
  }

  return image;
}

//gaussian blur for now
//might rename this to blur later
img.Image applyNoiseReduction(img.Image image, double value) {
  if (value <= 0.001) return image;

  final radius = (value * 3).round().clamp(1, 3);
  //might be faster if we implement this ourselves
  //to investigate later
  //as of now, this is the slowest basic operation and takes in between 400-1000ms
  return img.gaussianBlur(image, radius: radius);
}

img.Image applyGrain(img.Image image, double value) {
  if (value <= 0.001) return image;

  final data = _rgbaBytes(image);
  final random = Random(42);
  final intensity = value * 80;

  for (var i = 0; i < data.length; i += _channelsPerPixel) {
    // Grain adds the same monochrome noise amount to R, G, and B
    final noise = (random.nextDouble() * 2 - 1) * intensity;

    data[i] = _clampByteFloor(data[i] + noise);
    data[i + 1] = _clampByteFloor(data[i + 1] + noise);
    data[i + 2] = _clampByteFloor(data[i + 2] + noise);
  }

  return image;
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
