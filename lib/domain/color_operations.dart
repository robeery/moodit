import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../model/color_edit.dart';

//each range defined as (center, halfWidth) in degrees
//boundaries roughly aligned to Lightroom HSL ranges
const Map<ColorRange, (double, double)> _colorRangeParams = {
  ColorRange.red:     (0,   15),
  ColorRange.orange:  (30,  15),
  ColorRange.yellow:  (60,  15),
  ColorRange.green:   (112, 38),
  ColorRange.cyan:    (172, 18),   // core ends at 190, fades to 200
  ColorRange.blue:    (225, 30),   // core starts at 195, sky (200+) lands here
  ColorRange.purple:  (270, 15),
  ColorRange.magenta: (315, 30),
};

const int _channelsPerPixel = 4;
const int _hueWeightScale = 10;
const int _hueWeightTableSize = 360 * _hueWeightScale;

final List<Float32List> _hueWeightTables = [
  for (final range in ColorRange.values) _buildHueWeightTable(range),
];

Uint8List _rgbaBytes(img.Image image) => image.toUint8List();

int _clampByte(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toInt();
}

class HslValues {
  double hue = 0;
  double saturation = 0;
  double luminance = 0;
}

class RgbValues {
  double r = 0;
  double g = 0;
  double b = 0;
}

class _ColorShift {
  const _ColorShift({
    required this.range,
    required this.hue,
    required this.saturation,
    required this.luminance,
  });

  final ColorRange range;
  final double hue;
  final double saturation;
  final double luminance;

  bool get affectsHueOrSaturation =>
      hue.abs() > 0.001 || saturation.abs() > 0.001;
  bool get affectsLuminance => luminance.abs() > 0.001;
}

List<double> rgbToHsl(double r, double g, double b) {
  final hsl = HslValues();
  rgbToHslValues(r, g, b, hsl);
  return [hsl.hue, hsl.saturation, hsl.luminance];
}

void rgbToHslValues(double r, double g, double b, HslValues out) {
  final maxC = max(r, max(g, b));
  final minC = min(r, min(g, b));
  final delta = maxC - minC;

  double h = 0;
  double s = 0;
  final l = (maxC + minC) / 2;

  if (delta != 0) {
    s = l > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC);

    if (maxC == r) {
      h = ((g - b) / delta + (g < b ? 6 : 0)) / 6;
    } else if (maxC == g) {
      h = ((b - r) / delta + 2) / 6;
    } else {
      h = ((r - g) / delta + 4) / 6;
    }
  }

  out.hue = h * 360;
  out.saturation = s * 100;
  out.luminance = l * 100;
}

List<double> hslToRgb(double h, double s, double l) {
  final rgb = RgbValues();
  hslToRgbValues(h, s, l, rgb);
  return [rgb.r, rgb.g, rgb.b];
}

void hslToRgbValues(double h, double s, double l, RgbValues out) {
  s /= 100;
  l /= 100;
  h /= 360;

  if (s == 0) {
    final gray = l * 255;
    out.r = gray;
    out.g = gray;
    out.b = gray;
    return;
  }

  double hue2rgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }

  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;

  out.r = hue2rgb(p, q, h + 1 / 3) * 255;
  out.g = hue2rgb(p, q, h) * 255;
  out.b = hue2rgb(p, q, h - 1 / 3) * 255;
}
//raised cosine weight: 1.0 inside core, smooth fade at edges, 0 outside
const double _fadeWidth = 10.0;

double _hueWeight(double hue, ColorRange range, [double fade = _fadeWidth]) {
  final (center, halfWidth) = _colorRangeParams[range]!;
  double dist = (hue - center).abs();
  if (dist > 180) dist = 360 - dist;

  if (dist <= halfWidth) return 1.0;
  if (dist >= halfWidth + fade) return 0.0;

  //cosine fade in the transition zone
  final t = (dist - halfWidth) / fade;
  return 0.5 * (1.0 + cos(t * pi));
}

Float32List _buildHueWeightTable(ColorRange range) {
  final table = Float32List(_hueWeightTableSize);
  for (var i = 0; i < table.length; i++) {
    table[i] = _hueWeight(i / _hueWeightScale, range);
  }
  return table;
}

int _hueWeightIndex(double hue) {
  var index = (hue * _hueWeightScale).round();
  if (index >= _hueWeightTableSize) index -= _hueWeightTableSize;
  if (index < 0) index += _hueWeightTableSize;
  return index;
}

Float32List _hueWeightTable(ColorRange range) => _hueWeightTables[range.index];

//RGB-ratio-based color detection for luminance only
//ratios are stable across JPEG blocks since compression noise barely changes
//the relative balance between channels, unlike HSL hue which can jump wildly
double _rgbColorWeight(double r, double g, double b, ColorRange range) {
  final sum = r + g + b + 0.001;
  final maxC = max(r, max(g, b));
  final minC = min(r, min(g, b));
  final chroma = maxC - minC;
  final chromaGate = (chroma / 0.08).clamp(0.0, 1.0);

  double w;
  switch (range) {
    case ColorRange.red:
      //r is clearly the dominant channel
      w = ((r / sum - 0.4) / 0.15).clamp(0.0, 1.0) *
          ((r - max(g, b)) / (r + 0.001)).clamp(0.0, 1.0);
    case ColorRange.orange:
      //r highest with moderate green (g/r between 0.4 and 0.7)
      final gRatio = g / (r + 0.001);
      w = ((r / sum - 0.4) / 0.15).clamp(0.0, 1.0) *
          ((r - max(g, b)) / (r + 0.001)).clamp(0.0, 1.0) *
          ((gRatio - 0.4) / 0.3).clamp(0.0, 1.0) *
          ((0.7 - gRatio) / 0.3).clamp(0.0, 1.0) * 4.0;
    case ColorRange.yellow:
      //r and g both high, b low
      w = ((min(r, g) / (max(r, g) + 0.001) - 0.7) / 0.2).clamp(0.0, 1.0) *
          (((1 - b / sum) - 0.5) / 0.3).clamp(0.0, 1.0);
    case ColorRange.green:
      //g is clearly the dominant channel
      w = ((g / sum - 0.4) / 0.15).clamp(0.0, 1.0) *
          ((g - max(r, b)) / (g + 0.001)).clamp(0.0, 1.0);
    case ColorRange.cyan:
      //g and b both high, r low
      w = ((min(g, b) / (max(g, b) + 0.001) - 0.7) / 0.2).clamp(0.0, 1.0) *
          (((1 - r / sum) - 0.5) / 0.3).clamp(0.0, 1.0);
    case ColorRange.blue:
      //b is clearly the dominant channel
      w = ((b / sum - 0.4) / 0.15).clamp(0.0, 1.0) *
          ((b - max(r, g)) / (b + 0.001)).clamp(0.0, 1.0);
    case ColorRange.purple:
      //b and r both present, g low
      w = ((min(r, b) / (max(r, b) + 0.001) - 0.5) / 0.3).clamp(0.0, 1.0) *
          (((1 - g / sum) - 0.5) / 0.3).clamp(0.0, 1.0);
    case ColorRange.magenta:
      //r and b present with r dominant, g lowest
      w = ((min(r, b) / (max(r, b) + 0.001) - 0.5) / 0.3).clamp(0.0, 1.0) *
          (((1 - g / sum) - 0.5) / 0.3).clamp(0.0, 1.0) *
          ((r - b) / (r + 0.001)).clamp(0.0, 1.0);
  }

  return w * chromaGate;
}

//box blur on a flat array, averages available neighbors at edges
Float32List _boxBlur(Float32List data, int w, int h, int radius) {
  if (radius <= 0) return Float32List.fromList(data);

  final horizontal = Float32List(w * h);
  final out = Float32List(w * h);

  for (int y = 0; y < h; y++) {
    final rowStart = y * w;
    double sum = 0;
    int left = 0;
    int right = -1;

    for (int x = 0; x < w; x++) {
      final nextRight = min(w - 1, x + radius);
      while (right < nextRight) {
        right++;
        sum += data[rowStart + right];
      }

      final nextLeft = max(0, x - radius);
      while (left < nextLeft) {
        sum -= data[rowStart + left];
        left++;
      }

      horizontal[rowStart + x] = sum / (right - left + 1);
    }
  }

  for (int x = 0; x < w; x++) {
    double sum = 0;
    int top = 0;
    int bottom = -1;

    for (int y = 0; y < h; y++) {
      final nextBottom = min(h - 1, y + radius);
      while (bottom < nextBottom) {
        bottom++;
        sum += horizontal[bottom * w + x];
      }

      final nextTop = max(0, y - radius);
      while (top < nextTop) {
        sum -= horizontal[top * w + x];
        top++;
      }

      out[y * w + x] = sum / (bottom - top + 1);
    }
  }

  return out;
}

//applies all color edits in one go with pre-smoothed hue/sat and blurred luminance
img.Image applyAllColorEdits(img.Image image, List<ColorEdit> edits) {
  final activeEdits = edits.where((e) => !e.isEmpty).toList();
  if (activeEdits.isEmpty) return image;

  final w = image.width;
  final h = image.height;
  final n = w * h;
  final data = _rgbaBytes(image);

  final hueSatShifts = <_ColorShift>[];
  final hueSatWeights = <Float32List>[];
  final luminanceShifts = <_ColorShift>[];
  for (final edit in activeEdits) {
    final shift = _ColorShift(
      range: edit.range,
      hue: edit.hue / 100.0 * 40,
      saturation: edit.saturation / 100.0 * 100,
      luminance: edit.luminance / 100.0 * 30,
    );
    if (shift.affectsHueOrSaturation) {
      hueSatShifts.add(shift);
      hueSatWeights.add(_hueWeightTable(shift.range));
    }
    if (shift.affectsLuminance) luminanceShifts.add(shift);
  }

  final hasHueSatEdits = hueSatShifts.isNotEmpty;
  final hasLuminanceEdits = luminanceShifts.isNotEmpty;

  final originalSat = Float32List(n);
  final originalLum = Float32List(n);
  final hsl = HslValues();

  Float32List? originalHue;
  Float32List? smoothHue;
  Float32List? smoothSat;

  if (hasHueSatEdits) {
    //pre-processing: smooth chroma noise via YCbCr
    final yArr = Float32List(n);
    final cbArr = Float32List(n);
    final crArr = Float32List(n);

    for (var idx = 0, pixelOffset = 0;
        idx < n;
        idx++, pixelOffset += _channelsPerPixel) {
      final r = data[pixelOffset] / 255.0;
      final g = data[pixelOffset + 1] / 255.0;
      final b = data[pixelOffset + 2] / 255.0;
      rgbToHslValues(r, g, b, hsl);
      final yVal = 0.299 * r + 0.587 * g + 0.114 * b;
      yArr[idx] = yVal;
      cbArr[idx] = 0.564 * (b - yVal);
      crArr[idx] = 0.713 * (r - yVal);
      originalSat[idx] = hsl.saturation;
      originalLum[idx] = hsl.luminance;
    }

    //7x7 blur on chroma only, Y untouched
    final smoothCb = _boxBlur(cbArr, w, h, 3);
    final smoothCr = _boxBlur(crArr, w, h, 3);

    //reconstruct smoothed RGB - HSL for smoothHue/smoothSat
    smoothHue = Float32List(n);
    smoothSat = Float32List(n);
    for (int i = 0; i < n; i++) {
      final sr = (yArr[i] + 1.403 * smoothCr[i]).clamp(0.0, 1.0).toDouble();
      final sg = (yArr[i] - 0.344 * smoothCb[i] - 0.714 * smoothCr[i]).clamp(0.0, 1.0).toDouble();
      final sb = (yArr[i] + 1.770 * smoothCb[i]).clamp(0.0, 1.0).toDouble();
      rgbToHslValues(sr, sg, sb, hsl);
      smoothHue[i] = hsl.hue;
      smoothSat[i] = hsl.saturation;
    }
  } else {
    originalHue = Float32List(n);

    for (var idx = 0, pixelOffset = 0;
        idx < n;
        idx++, pixelOffset += _channelsPerPixel) {
      final r = data[pixelOffset] / 255.0;
      final g = data[pixelOffset + 1] / 255.0;
      final b = data[pixelOffset + 2] / 255.0;
      rgbToHslValues(r, g, b, hsl);
      originalHue[idx] = hsl.hue;
      originalSat[idx] = hsl.saturation;
      originalLum[idx] = hsl.luminance;
    }
  }

  //pass 1: compute per-pixel luminance delta using RGB ratio detection
  Float32List? blurredLum;

  if (hasLuminanceEdits) {
    final lumDeltas = Float32List(n);

    for (var idx = 0, pixelOffset = 0;
        idx < n;
        idx++, pixelOffset += _channelsPerPixel) {
      final r = data[pixelOffset] / 255.0;
      final g = data[pixelOffset + 1] / 255.0;
      final b = data[pixelOffset + 2] / 255.0;
      final l = originalLum[idx];

      double totalLum = 0;
      double totalLumW = 0;

      for (final shift in luminanceShifts) {
        final lumW = _rgbColorWeight(r, g, b, shift.range);
        if (lumW > 0.01) {
          totalLum += shift.luminance * lumW;
          totalLumW += lumW;
        }
      }

      if (totalLumW > 1.0) totalLum /= totalLumW;

      //soft power curve to compute the final delta
      double newL;
      if (totalLum >= 0) {
        final t = l / 100.0;
        final shifted = t + totalLum / 100.0 * (1 - t * t);
        newL = shifted.clamp(0.0, 1.0) * 100.0;
      } else {
        final t = l / 100.0;
        final shifted = t + totalLum / 100.0 * (t * (2 - t));
        newL = shifted.clamp(0.0, 1.0) * 100.0;
      }

      lumDeltas[idx] = newL - l;
    }

    //pass 2: 5x5 blur the luminance deltas
    blurredLum = _boxBlur(lumDeltas, w, h, 2);
  }

  final rgbOut = RgbValues();

  //pass 3: apply hue/sat (using smoothed values) + blurred luminance
  if (hasHueSatEdits) {
    final hueValues = smoothHue!;
    final satValues = smoothSat!;

    for (var idx = 0, pixelOffset = 0;
        idx < n;
        idx++, pixelOffset += _channelsPerPixel) {
      final l = originalLum[idx];

      final sHue = hueValues[idx];
      final sSat = satValues[idx];

      final satGate = (sSat / 30.0).clamp(0.0, 1.0);
      final hueWeightIndex = _hueWeightIndex(sHue);

      double totalHue = 0;
      double totalSat = 0;
      double maxW = 0;

      for (var i = 0; i < hueSatShifts.length; i++) {
        final wt = hueSatWeights[i][hueWeightIndex] * satGate;
        if (wt > 0.01) {
          final shift = hueSatShifts[i];
          totalHue += shift.hue * wt;
          totalSat += shift.saturation * wt;
          if (wt > maxW) maxW = wt;
        }
      }

      final lumDelta = blurredLum == null ? 0.0 : blurredLum[idx];
      if (maxW <= 0.01 && lumDelta.abs() <= 0.01) continue;

      final newH = (sHue + totalHue) % 360;
      final newS = (originalSat[idx] + totalSat).clamp(0.0, 100.0).toDouble();
      final newL = (l + lumDelta).clamp(0.0, 100.0).toDouble();

      hslToRgbValues(newH, newS, newL, rgbOut);

      data[pixelOffset] = _clampByte(rgbOut.r);
      data[pixelOffset + 1] = _clampByte(rgbOut.g);
      data[pixelOffset + 2] = _clampByte(rgbOut.b);
    }
  } else {
    final hueValues = originalHue!;
    final lumDeltas = blurredLum!;

    for (var idx = 0, pixelOffset = 0;
        idx < n;
        idx++, pixelOffset += _channelsPerPixel) {
      final lumDelta = lumDeltas[idx];
      if (lumDelta.abs() <= 0.01) continue;

      final newL = (originalLum[idx] + lumDelta).clamp(0.0, 100.0).toDouble();
      hslToRgbValues(hueValues[idx], originalSat[idx], newL, rgbOut);

      data[pixelOffset] = _clampByte(rgbOut.r);
      data[pixelOffset + 1] = _clampByte(rgbOut.g);
      data[pixelOffset + 2] = _clampByte(rgbOut.b);
    }
  }

  return image;
}
