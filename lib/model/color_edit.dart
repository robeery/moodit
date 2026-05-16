enum ColorRange {
  red,
  orange,
  yellow,
  green,
  cyan,
  blue,
  purple,
  magenta,
}

class ColorEdit {
  final ColorRange range;
  final double hue;
  final double saturation;
  final double luminance;

  ColorEdit({
    required this.range,
    double hue = 0,
    double saturation = 0,
    double luminance = 0,
  })  : hue = hue.round().toDouble(),
        saturation = saturation.round().toDouble(),
        luminance = luminance.round().toDouble();

  ColorEdit copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return ColorEdit(
      range: range,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  bool get isEmpty =>
      hue.abs() < 0.001 &&
      saturation.abs() < 0.001 &&
      luminance.abs() < 0.001;

  factory ColorEdit.fromJson(Map<String, dynamic> json) {
    final rangeName = json['range'];
    if (rangeName is! String) {
      throw const FormatException('Color edit range must be a string');
    }

    final ColorRange range;
    try {
      range = ColorRange.values.byName(rangeName);
    } catch (_) {
      throw FormatException('Unknown color range: $rangeName');
    }

    return ColorEdit(
      range: range,
      hue: _readAdjustment(json, 'hue'),
      saturation: _readAdjustment(json, 'saturation'),
      luminance: _readAdjustment(json, 'luminance'),
    );
  }

  static double _readAdjustment(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return 0;
    if (value is! num) {
      throw FormatException('Color edit $key must be a number');
    }

    final normalized = value.toDouble();
    if (normalized < -100 || normalized > 100) {
      throw FormatException('Color edit $key out of range: $normalized');
    }
    return normalized;
  }

  Map<String, dynamic> toJson() => {
        'range': range.name,
        'hue': hue,
        'saturation': saturation,
        'luminance': luminance,
      };
      
  //debug purposes
  @override
  String toString() =>
      'ColorEdit(${range.name}: H=$hue, S=$saturation, L=$luminance)';
}
