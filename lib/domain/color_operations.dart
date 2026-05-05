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

Uint8List _rgbaBytes(img.Image image) => image.toUint8List();

int _clampByte(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toInt();
}

List<double> rgbToHsl(double r, double g, double b) {
  final max = [r, g, b].reduce((a, b) => a > b ? a : b);
  final min = [r, g, b].reduce((a, b) => a < b ? a : b);
  final delta = max - min;

  double h = 0;
  double s = 0;
  final l = (max + min) / 2;

  if (delta != 0) {
    s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);

    if (max == r) {
      h = ((g - b) / delta + (g < b ? 6 : 0)) / 6;
    } else if (max == g) {
      h = ((b - r) / delta + 2) / 6;
    } else {
      h = ((r - g) / delta + 4) / 6;
    }
  }

  return [h * 360, s * 100, l * 100];
}

List<double> hslToRgb(double h, double s, double l) {
  s /= 100;
  l /= 100;
  h /= 360;

  if (s == 0) return [l * 255, l * 255, l * 255];

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

  return [
    hue2rgb(p, q, h + 1 / 3) * 255,
    hue2rgb(p, q, h) * 255,
    hue2rgb(p, q, h - 1 / 3) * 255,
  ];
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
Float64List _boxBlur(Float64List data, int w, int h, int radius) {
  if (radius <= 0) return Float64List.fromList(data);

  final horizontal = Float64List(w * h);
  final out = Float64List(w * h);

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

  //precompute shift values
  final shifts = activeEdits.map((e) => (
    range: e.range,
    hue: e.hue / 100.0 * 40,
    sat: e.saturation / 100.0 * 100,
    lum: e.luminance / 100.0 * 30,
  )).toList();

  //pre-processing: smooth chroma noise via YCbCr
  final yArr = Float64List(n);
  final cbArr = Float64List(n);
  final crArr = Float64List(n);

  for (var idx = 0, pixelOffset = 0;
      idx < n;
      idx++, pixelOffset += _channelsPerPixel) {
    final r = data[pixelOffset] / 255.0;
    final g = data[pixelOffset + 1] / 255.0;
    final b = data[pixelOffset + 2] / 255.0;
    final yVal = 0.299 * r + 0.587 * g + 0.114 * b;
    yArr[idx] = yVal;
    cbArr[idx] = 0.564 * (b - yVal);
    crArr[idx] = 0.713 * (r - yVal);
  }

  //7x7 blur on chroma only, Y untouched
  final smoothCb = _boxBlur(cbArr, w, h, 3);
  final smoothCr = _boxBlur(crArr, w, h, 3);

  //reconstruct smoothed RGB - HSL for smoothHue/smoothSat
  final smoothHue = Float64List(n);
  final smoothSat = Float64List(n);
  for (int i = 0; i < n; i++) {
    final sr = (yArr[i] + 1.403 * smoothCr[i]).clamp(0.0, 1.0);
    final sg = (yArr[i] - 0.344 * smoothCb[i] - 0.714 * smoothCr[i]).clamp(0.0, 1.0);
    final sb = (yArr[i] + 1.770 * smoothCb[i]).clamp(0.0, 1.0);
    final hsl = rgbToHsl(sr, sg, sb);
    smoothHue[i] = hsl[0];
    smoothSat[i] = hsl[1];
  }

  //pass 1: compute per-pixel luminance delta using RGB ratio detection
  final lumDeltas = Float64List(n);

  for (var idx = 0, pixelOffset = 0;
      idx < n;
      idx++, pixelOffset += _channelsPerPixel) {
    final r = data[pixelOffset] / 255.0;
    final g = data[pixelOffset + 1] / 255.0;
    final b = data[pixelOffset + 2] / 255.0;
    final hsl = rgbToHsl(r, g, b);
    final l = hsl[2];

    double totalLum = 0;
    double totalLumW = 0;

    for (final shift in shifts) {
      final lumW = _rgbColorWeight(r, g, b, shift.range);
      if (lumW > 0.01) {
        totalLum += shift.lum * lumW;
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
  final blurredLum = _boxBlur(lumDeltas, w, h, 2);

  //pass 3: apply hue/sat (using smoothed values) + blurred luminance
  for (var idx = 0, pixelOffset = 0;
      idx < n;
      idx++, pixelOffset += _channelsPerPixel) {
    final r = data[pixelOffset] / 255.0;
    final g = data[pixelOffset + 1] / 255.0;
    final b = data[pixelOffset + 2] / 255.0;

    final hsl = rgbToHsl(r, g, b);
    final l = hsl[2];

    final sHue = smoothHue[idx];
    final sSat = smoothSat[idx];

    final satGate = (sSat / 30.0).clamp(0.0, 1.0);

    double totalHue = 0;
    double totalSat = 0;
    double maxW = 0;

    for (final shift in shifts) {
      final wt = _hueWeight(sHue, shift.range) * satGate;
      if (wt > 0.01) {
        totalHue += shift.hue * wt;
        totalSat += shift.sat * wt;
        if (wt > maxW) maxW = wt;
      }
    }

    final lumDelta = blurredLum[idx];
    if (maxW <= 0.01 && lumDelta.abs() <= 0.01) continue;

    final newH = (sHue + totalHue) % 360;
    final newS = (hsl[1] + totalSat).clamp(0.0, 100.0);
    final newL = (l + lumDelta).clamp(0.0, 100.0);

    final rgb = hslToRgb(newH, newS, newL);

    data[pixelOffset] = _clampByte(rgb[0]);
    data[pixelOffset + 1] = _clampByte(rgb[1]);
    data[pixelOffset + 2] = _clampByte(rgb[2]);
  }

  return image;
}
