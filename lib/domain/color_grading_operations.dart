
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../model/color_grading_edit.dart';
import 'color_operations.dart' show HslValues, RgbValues, rgbToHslValues, hslToRgbValues;

const int _channelsPerPixel = 4;
const int _zoneWeightBucketCount = 256;

final int _zoneCount = ColorGradingZone.values.length;
final Float32List _zoneWeightLut = _buildZoneWeightLut();

Uint8List _rgbaBytes(img.Image image) => image.toUint8List();

int _clampByte(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toInt();
}

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

//smooth ramps that partition 0-255 cleanly (shadows + midtones + highlights = 1.0)
Float32List _buildZoneWeightLut() {
  final lut = Float32List(_zoneWeightBucketCount * _zoneCount);

  for (var lumByte = 0; lumByte < _zoneWeightBucketCount; lumByte++) {
    final n = lumByte / 255.0;
    final shadows = _shadowZoneWeight(n);
    final highlights = _highlightZoneWeight(n);
    final base = lumByte * _zoneCount;

    lut[base + ColorGradingZone.shadows.index] = shadows;
    lut[base + ColorGradingZone.midtones.index] = 1.0 - shadows - highlights;
    lut[base + ColorGradingZone.highlights.index] = highlights;
    lut[base + ColorGradingZone.global.index] = 1.0;
  }

  return lut;
}

double _shadowZoneWeight(double normalizedLum) {
  if (normalizedLum <= 0.25) return 1.0;
  if (normalizedLum >= 0.5) return 0.0;
  final phase = ((normalizedLum - 0.25) / 0.25).clamp(0.0, 1.0);
  return 0.5 * (1 + cos(phase * pi));
}

double _highlightZoneWeight(double normalizedLum) {
  if (normalizedLum <= 0.5) return 0.0;
  if (normalizedLum >= 0.75) return 1.0;
  final phase = ((normalizedLum - 0.5) / 0.25).clamp(0.0, 1.0);
  return 0.5 * (1 - cos(phase * pi));
}

int _luminanceBucket(double yVal) {
  final lumByte = (yVal * 255.0).round();
  if (lumByte <= 0) return 0;
  if (lumByte >= 255) return 255;
  return lumByte;
}



double _lerpHue(double from, double to, double t) {
  double diff = (to - from) % 360;
  if (diff > 180) diff -= 360;                    
  return (from + diff * t) % 360;
}

img.Image applyColorGrading(img.Image image, List<ColorGradingEdit> edits) {
  final activeEdits = edits.where((e) => !e.isEmpty).toList();
  if (activeEdits.isEmpty) return image;

  final imgW = image.width;
  final imgH = image.height;
  final n = imgW * imgH;
  final data = _rgbaBytes(image);

  // Pre-processing: smooth chroma noise via YCbCr
  final cbArr = Float32List(n);
  final crArr = Float32List(n);
  final yArr = Float32List(n);

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

  final smoothCb = _boxBlur(cbArr, imgW, imgH, 3);
  final smoothCr = _boxBlur(crArr, imgW, imgH, 3);
  final hsl = HslValues();
  final rgbOut = RgbValues();

  for (var idx = 0, pixelOffset = 0;
      idx < n;
      idx++, pixelOffset += _channelsPerPixel) {
    // Reconstruct smoothed RGB from original Y + blurred chroma
    final yVal = yArr[idx];
    final sr = (yVal + 1.403 * smoothCr[idx]).clamp(0.0, 1.0).toDouble();
    final sg = (yVal - 0.344 * smoothCb[idx] - 0.714 * smoothCr[idx]).clamp(0.0, 1.0).toDouble();
    final sb = (yVal + 1.770 * smoothCb[idx]).clamp(0.0, 1.0).toDouble();

    final zoneWeightBase = _luminanceBucket(yVal) * _zoneCount;

    rgbToHslValues(sr, sg, sb, hsl);
    double h = hsl.hue;
    double s = hsl.saturation;
    final l = hsl.luminance;

    double newL = l;

    for (final edit in activeEdits) {
      final w = _zoneWeightLut[zoneWeightBase + edit.zone.index];
      final t = w * (edit.strength / 100.0);

      // Blend toward the target tint as a fixed color
      const tintSat = 40.0;
      h = _lerpHue(h, edit.hue, t);
      s = s + (tintSat - s) * t;
      s = s.clamp(0.0, 100.0);

      // Apply luminance shift with proportional power curve
      if (edit.luminance.abs() > 0.001) {
        final lumShift = w * (edit.luminance / 100.0) * 15;
        final lt = newL / 100.0;
        if (lumShift >= 0) {
          newL = (lt + lumShift / 100.0 * (1 - lt * lt)).clamp(0.0, 1.0) * 100.0;
        } else {
          newL = (lt + lumShift / 100.0 * (lt * (2 - lt))).clamp(0.0, 1.0) * 100.0;
        }
      }
    }

    hslToRgbValues(h, s, newL, rgbOut);

    data[pixelOffset] = _clampByte(rgbOut.r);
    data[pixelOffset + 1] = _clampByte(rgbOut.g);
    data[pixelOffset + 2] = _clampByte(rgbOut.b);
  }

  return image;
}
