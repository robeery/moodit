import 'package:flutter/material.dart';
import '../model/color_edit.dart';

// Selective color swatch colors. Functional color data for the color panel,
// kept separate from the cinematic chrome tokens in MooditColors.
class SelectiveColorSwatches {
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
