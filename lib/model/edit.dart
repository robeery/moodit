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

  factory Edit.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    final rawValue = json['value'];

    if (typeName is! String) {
      throw const FormatException('Edit type must be a string');
    }
    if (rawValue is! num) {
      throw const FormatException('Edit value must be a number');
    }

    final OperationType type;
    try {
      type = OperationType.values.byName(typeName);
    } catch (_) {
      throw FormatException('Unknown operation type: $typeName');
    }

    final value = rawValue.toDouble();
    if (value < type.minValue || value > type.maxValue) {
      throw FormatException('Edit value out of range for $typeName: $value');
    }

    return Edit(type: type, value: value);
  }

  Map<String, dynamic> toJson() => {'type': type.name, 'value': value};
}
