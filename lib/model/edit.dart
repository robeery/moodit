enum OperationType {
  exposure,
  warmth,
  tint,
  brightness,
  highlights,
  shadows,
  contrast,
  blackpoint,
  saturation,
  vibrance,
  definition,
  sharpness,
  vignette,
  blur,
  grain,
  fade,
}

extension OperationTypeExtension on OperationType {
  double get minValue {
    switch (this) {
      case OperationType.sharpness:
      case OperationType.definition:
      case OperationType.blackpoint:
      case OperationType.blur:
      case OperationType.grain:
      case OperationType.fade:
        return 0;
      default:
        return -100;
    }
  }

  double get maxValue => 100;
}

class Edit {
  final OperationType type;
  final double value;

  //debug purposes
  @override
  String  toString() => 'Edit(${type.name}: $value)';
  

  
  Edit({required this.type, required double value})
      : value = value.round().toDouble();

  Map<String, dynamic> toJson() => {'type': type.name, 'value': value};
}
