
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../model/color_grading_edit.dart';
import 'color_operations.dart' show rgbToHsl, hslToRgb;

const int _channelsPerPixel = 4;

Uint8List _rgbaBytes(img.Image image) => image.toUint8List();

int _clampByte(num value) {
  if (value <= 0) return 0;
  if (value >= 255) return 255;
  return value.toInt();
}

Float64List _boxBlur(Float64List data, int w, int h, int radius) {
  final out = Float64List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      double sum = 0;
      int count = 0;
      for (int dy = -radius; dy <= radius; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        for (int dx = -radius; dx <= radius; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) continue;
          sum += data[ny * w + nx];
          count++;
        }
      }
      out[y * w + x] = sum / count;
    }
  }
  return out;
}

//smooth ramps that partition 0-255 cleanly (shadows + midtones + highlights = 1.0)
double _zoneWeight(double lum, ColorGradingZone zone) {
  final n = lum / 255.0; // normalized 0..1
  switch (zone) {
    case ColorGradingZone.shadows:
      if (n <= 0.25) return 1.0;
      if (n >= 0.5) return 0.0;
      final ps = ((n - 0.25) / 0.25).clamp(0.0, 1.0);
      return 0.5 * (1 + cos(ps * pi));
    case ColorGradingZone.highlights:
      if (n <= 0.5) return 0.0;
      if (n >= 0.75) return 1.0;
      final ph = ((n - 0.5) / 0.25).clamp(0.0, 1.0);
      return 0.5 * (1 - cos(ph * pi));
    case ColorGradingZone.midtones:
      final sw = _zoneWeight(lum, ColorGradingZone.shadows);
      final hw = _zoneWeight(lum, ColorGradingZone.highlights);
      return 1.0 - sw - hw;
    case ColorGradingZone.global:
      return 1.0;
  }
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
  final cbArr = Float64List(n);
  final crArr = Float64List(n);
  final yArr = Float64List(n);

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

  for (var idx = 0, pixelOffset = 0;
      idx < n;
      idx++, pixelOffset += _channelsPerPixel) {
    // Reconstruct smoothed RGB from original Y + blurred chroma
    final yVal = yArr[idx];
    final sr = (yVal + 1.403 * smoothCr[idx]).clamp(0.0, 1.0);
    final sg = (yVal - 0.344 * smoothCb[idx] - 0.714 * smoothCr[idx]).clamp(0.0, 1.0);
    final sb = (yVal + 1.770 * smoothCb[idx]).clamp(0.0, 1.0);

    final lum = yVal * 255.0;

    final hsl = rgbToHsl(sr, sg, sb);
    double h = hsl[0];
    double s = hsl[1];
    final l = hsl[2];

    double newL = l;

    for (final edit in activeEdits) {
      final w = _zoneWeight(lum, edit.zone);
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

    final rgb = hslToRgb(h, s, newL);

    data[pixelOffset] = _clampByte(rgb[0]);
    data[pixelOffset + 1] = _clampByte(rgb[1]);
    data[pixelOffset + 2] = _clampByte(rgb[2]);
  }

  return image;
}
