import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../model/edit.dart';
import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';
import 'image_operations.dart';
import 'color_operations.dart' as color_ops;
import 'color_grading_operations.dart' as grading_ops;

Uint8List applyEditsSync({
  required Uint8List originalBytes,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
}) {
  img.Image image = img.decodeImage(originalBytes)!;
  final editValues = <OperationType, double>{
    for (final edit in edits) edit.type: edit.value / 100.0,
  };

  void ensureRgba() {
    if (image.hasPalette ||
        image.format != img.Format.uint8 ||
        image.numChannels != 4) {
      image = image.convert(format: img.Format.uint8, numChannels: 4);
    }
  }

  double valueFor(OperationType type) => editValues[type] ?? 0.0;
  bool hasSignedValue(OperationType type) => valueFor(type).abs() > 0.001;
  bool hasPositiveValue(OperationType type) => valueFor(type) > 0.001;

  if (hasSignedValue(OperationType.exposure) ||
      hasSignedValue(OperationType.warmth) ||
      hasSignedValue(OperationType.tint) ||
      hasSignedValue(OperationType.brightness)) {
    ensureRgba();
    image = applyFusedColorBalanceOps(
      image,
      exposure: valueFor(OperationType.exposure),
      warmth: valueFor(OperationType.warmth),
      tint: valueFor(OperationType.tint),
      brightness: valueFor(OperationType.brightness),
    );
  }

  if (hasSignedValue(OperationType.highlights)) {
    ensureRgba();
    image = applyHighlights(image, valueFor(OperationType.highlights));
  }

  if (hasSignedValue(OperationType.shadows)) {
    ensureRgba();
    image = applyShadows(image, valueFor(OperationType.shadows));
  }

  if (hasSignedValue(OperationType.contrast)) {
    ensureRgba();
    image = applyContrast(image, valueFor(OperationType.contrast));
  }

  if (hasPositiveValue(OperationType.blackpoint)) {
    ensureRgba();
    image = applyBlackpoint(image, valueFor(OperationType.blackpoint));
  }

  if (hasSignedValue(OperationType.saturation)) {
    ensureRgba();
    image = applySaturation(image, valueFor(OperationType.saturation));
  }

  if (hasSignedValue(OperationType.vibrance)) {
    ensureRgba();
    image = applyVibrance(image, valueFor(OperationType.vibrance));
  }

  // Definition is still disabled because it is too slow for interactive use.

  if (hasSignedValue(OperationType.sharpness)) {
    ensureRgba();
    image = applySharpness(image, valueFor(OperationType.sharpness));
  }

  if (hasSignedValue(OperationType.vignette)) {
    ensureRgba();
    image = applyVignette(image, valueFor(OperationType.vignette));
  }

  if (hasPositiveValue(OperationType.noiseReduction)) {
    ensureRgba();
    image = applyNoiseReduction(image, valueFor(OperationType.noiseReduction));
  }

  if (hasPositiveValue(OperationType.grain)) {
    ensureRgba();
    image = applyGrain(image, valueFor(OperationType.grain));
  }

  if (hasPositiveValue(OperationType.fade)) {
    ensureRgba();
    image = applyFade(image, valueFor(OperationType.fade));
  }

  image = color_ops.applyAllColorEdits(image, colorEdits);

  image = grading_ops.applyColorGrading(image, colorGradingEdits);

  return Uint8List.fromList(img.encodeJpg(image));
}

Uint8List _applyEditsInIsolate(Map<String, dynamic> params) {
  return applyEditsSync(
    originalBytes: params['bytes'] as Uint8List,
    edits: params['edits'] as List<Edit>,
    colorEdits: params['colorEdits'] as List<ColorEdit>,
    colorGradingEdits: params['colorGradingEdits'] as List<ColorGradingEdit>,
  );
}

Future<Uint8List> processAllEdits({
  required Uint8List originalBytes,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
}) async {
  if (edits.isEmpty && colorEdits.isEmpty && colorGradingEdits.isEmpty) {
    return originalBytes;
  }

  return await compute(_applyEditsInIsolate, {
    'bytes': originalBytes,
    'edits': edits,
    'colorEdits': colorEdits,
    'colorGradingEdits': colorGradingEdits,
  });
}
