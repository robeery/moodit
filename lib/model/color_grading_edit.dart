
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
