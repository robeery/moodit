import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../model/ai_profile_settings.dart';
import '../model/color_edit.dart';
import 'app_tokens.dart';

// Selective color swatch colors. Functional color data for the color panel,
// kept separate from the cinematic chrome tokens in MooditColors.
class AppColors {
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

// Per provider gradient stops; start is also used for
// borders, icon strokes and text where a gradient does not render well.
List<Color> aiProviderGradientColors(String? providerId) {
  switch (providerId) {
    case AiProfileSettings.openAiProviderId:
      return const [Color(0xFF34D6C1), Color(0xFF2A9BD6)];
    case AiProfileSettings.claudeProviderId:
      return const [Color(0xFFE9A24C), Color(0xFFE9624C)];
    case AiProfileSettings.geminiProviderId:
    default:
      return const [Color(0xFF4C8DF6), Color(0xFF9B5CF6)];
  }
}

LinearGradient aiProviderGradient(String? providerId) {
  return LinearGradient(
    colors: aiProviderGradientColors(providerId),
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

Color aiProviderStartColor(String? providerId) =>
    aiProviderGradientColors(providerId).first;

String aiProviderTag(String? providerId) {
  switch (providerId) {
    case AiProfileSettings.openAiProviderId:
      return 'OPENAI';
    case AiProfileSettings.claudeProviderId:
      return 'ANTHROPIC';
    case AiProfileSettings.geminiProviderId:
    default:
      return 'GOOGLE';
  }
}

class AppSliderTheme {
  static SliderThemeData of(BuildContext context) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: MooditColors.baseAccent,
        inactiveTrackColor: MooditColors.hairlineStrong,
        thumbColor: MooditColors.baseAccent,
        overlayColor: MooditColors.baseGlow,
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
