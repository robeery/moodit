
enum ColorGradingZone { shadows, midtones, highlights, global }

class ColorGradingEdit {
  final ColorGradingZone zone;
  final double hue;        // 0-360 -> target tint color in degrees
  final double strength;   // 0-100 -> how strongly the tint is applied
  final double luminance;  // -100..+100 -> brighten/darken this zone

  ColorGradingEdit({
    required this.zone,
    double hue = 0,
    double strength = 0,
    double luminance = 0,
  })  : hue = hue.round().toDouble(),
        strength = strength.round().toDouble(),
        luminance = luminance.round().toDouble();

  ColorGradingEdit copyWith({
    double? hue,
    double? strength,
    double? luminance,
  }) {
    return ColorGradingEdit(
      zone: zone,
      hue: hue ?? this.hue,
      strength: strength ?? this.strength,
      luminance: luminance ?? this.luminance,
    );
  }

  bool get isEmpty => strength.abs() < 0.001 && luminance.abs() < 0.001;

  factory ColorGradingEdit.fromJson(Map<String, dynamic> json) {
    final zoneName = json['zone'];
    if (zoneName is! String) {
      throw const FormatException('Color grading zone must be a string');
    }

    final ColorGradingZone zone;
    try {
      zone = ColorGradingZone.values.byName(zoneName);
    } catch (_) {
      throw FormatException('Unknown color grading zone: $zoneName');
    }

    return ColorGradingEdit(
      zone: zone,
      hue: _readValue(json, 'hue', min: 0, max: 360),
      strength: _readValue(json, 'strength', min: 0, max: 100),
      luminance: _readValue(json, 'luminance', min: -100, max: 100),
    );
  }

  static double _readValue(
    Map<String, dynamic> json,
    String key, {
    required double min,
    required double max,
  }) {
    final value = json[key];
    if (value == null) return 0;
    if (value is! num) {
      throw FormatException('Color grading $key must be a number');
    }

    final normalized = value.toDouble();
    if (normalized < min || normalized > max) {
      throw FormatException('Color grading $key out of range: $normalized');
    }
    return normalized;
  }

  Map<String, dynamic> toJson() => {
        'zone': zone.name,
        'hue': hue,
        'strength': strength,
        'luminance': luminance,
      };

  //debug purposes
  @override
  String toString() =>
      'ColorGradingEdit(${zone.name}: H=$hue°, S=$strength%, L=$luminance)';
}
