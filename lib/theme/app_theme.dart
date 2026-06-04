import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../model/ai_profile_settings.dart';
import '../model/color_edit.dart';

class AppColors {
  static const bg        = Color(0xFF111111);
  static const surface   = Color(0xFF1E1E1E);
  static const accent    = Color(0xFFE0E0E0);
  static const muted     = Color(0xFF555555);
  static const highlight = Color(0xFFFFFFFF);

  static const colorRange = <ColorRange, Color>{
    ColorRange.red:     Color(0xFFFF3B30),
    ColorRange.orange:  Color(0xFFFF9500),
    ColorRange.yellow:  Color(0xFFFFCC00),
    ColorRange.green:   Color(0xFF34C759),
    ColorRange.cyan:    Color(0xFF5AC8FA),
    ColorRange.blue:    Color(0xFF007AFF),
    ColorRange.purple:  Color(0xFFAF52DE),
    ColorRange.magenta: Color(0xFFFF2D55),
  };
}

LinearGradient aiProviderGradient(String? providerId) {
  switch (providerId) {
    case AiProfileSettings.openAiProviderId:
      return const LinearGradient(
        colors: [Color(0xFF10A37F), Color(0xFFC6F6E3)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    case AiProfileSettings.geminiProviderId:
    default:
      return const LinearGradient(
        colors: [Color(0xFF1FBC9C), Color(0xFF647EFF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
  }
}

class AppTextStyles {
  static const screenTitle = TextStyle(
    color: AppColors.highlight,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );

  static const sectionLabel = TextStyle(
    color: AppColors.highlight,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );

  static const sliderLabel = TextStyle(
    color: AppColors.accent,
    fontSize: 11,
    letterSpacing: 3,
    fontWeight: FontWeight.w500,
  );

  static const sliderValue = TextStyle(
    color: AppColors.highlight,
    fontSize: 13,
    fontWeight: FontWeight.w300,
    letterSpacing: 1,
  );

  static const chipLabel = TextStyle(
    color: AppColors.muted,
    fontSize: 11,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );

  static const mutedSmall = TextStyle(
    color: AppColors.muted,
    fontSize: 10,
    letterSpacing: 2,
  );
}

class AppSliderTheme {
  static SliderThemeData of(BuildContext context) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 1,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: AppColors.highlight,
        inactiveTrackColor: AppColors.muted,
        thumbColor: AppColors.highlight,
        overlayColor: Colors.white12,
      );
}

/// Center hue (degrees) for each color range  used for gradient sliders
const Map<ColorRange, double> _rangeHue = {
  ColorRange.red: 0,
  ColorRange.orange: 30,
  ColorRange.yellow: 60,
  ColorRange.green: 120,
  ColorRange.cyan: 180,
  ColorRange.blue: 225,
  ColorRange.purple: 270,
  ColorRange.magenta: 315,
};

/// Converts HSL (h 0-360, s/l 0-1) to a Flutter Color
Color _hslColor(double h, double s, double l) {
  final hue = ((h % 360) + 360) % 360;
  return HSLColor.fromAHSL(1.0, hue, s.clamp(0.0, 1.0), l.clamp(0.0, 1.0)).toColor();
}

/// Builds a gradient for the hue slider, shows neighboring hues
List<Color> hueGradientColors(ColorRange range) {
  final center = _rangeHue[range]!;
  return [
    _hslColor(center - 40, 0.5, 0.45),
    _hslColor(center - 20, 0.5, 0.45),
    _hslColor(center, 0.5, 0.45),
    _hslColor(center + 20, 0.5, 0.45),
    _hslColor(center + 40, 0.5, 0.45),
  ];
}

/// Builds a gradient for the saturation slider, gray to full color
List<Color> saturationGradientColors(ColorRange range) {
  final center = _rangeHue[range]!;
  return [
    _hslColor(center, 0.0, 0.4),
    _hslColor(center, 0.5, 0.45),
  ];
}

/// Builds a gradient for the luminance slider, dark to bright
List<Color> luminanceGradientColors(ColorRange range) {
  final center = _rangeHue[range]!;
  return [
    _hslColor(center, 0.4, 0.2),
    _hslColor(center, 0.5, 0.45),
    _hslColor(center, 0.4, 0.7),
  ];
}

/// Rainbow gradient for color grading hue slider (0-360)
List<Color> gradingHueGradientColors() {
  return [
    _hslColor(0, 0.5, 0.45),
    _hslColor(60, 0.5, 0.45),
    _hslColor(120, 0.5, 0.45),
    _hslColor(180, 0.5, 0.45),
    _hslColor(240, 0.5, 0.45),
    _hslColor(300, 0.5, 0.45),
    _hslColor(360, 0.5, 0.45),
  ];
}

/// Gradient for color grading strength slider, gray to the selected hue
List<Color> gradingStrengthGradientColors(double hue) {
  return [
    _hslColor(hue, 0.0, 0.35),
    _hslColor(hue, 0.5, 0.45),
  ];
}

/// Gradient for color grading luminance slider — dark to bright (zone-tinted)
List<Color> gradingLuminanceGradientColors() {
  return [
    _hslColor(0, 0.0, 0.15),
    _hslColor(0, 0.0, 0.5),
    _hslColor(0, 0.0, 0.85),
  ];
}

/// A slider track that paints a horizontal gradient instead of flat colors
class GradientSliderTrackShape extends SliderTrackShape {
  final List<Color> colors;

  const GradientSliderTrackShape({required this.colors});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackLeft = offset.dx + 7;
    final trackWidth = parentBox.size.width - 14;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        rect.centerLeft,
        rect.centerRight,
        colors,
      );
    context.canvas.drawRRect(rrect, paint);
  }
}
