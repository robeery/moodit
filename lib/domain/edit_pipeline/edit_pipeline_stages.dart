import 'package:image/image.dart' as img;

import '../../model/color_edit.dart';
import '../../model/color_grading_edit.dart';
import '../../model/edit.dart';
import '../color_grading_operations.dart' as grading_ops;
import '../color_operations.dart' as color_ops;
import '../image_operations.dart';
import 'image_frame_codec.dart';

img.Image applyBasicEditsToImageSync({
  required img.Image image,
  required List<Edit> edits,
}) {
  image = ensureEditableImage(image);

  final editValues = <OperationType, double>{
    for (final edit in edits) edit.type: edit.value / 100.0,
  };

  double valueFor(OperationType type) => editValues[type] ?? 0.0;
  bool hasSignedValue(OperationType type) => valueFor(type).abs() > 0.001;
  bool hasPositiveValue(OperationType type) => valueFor(type) > 0.001;

  if (hasSignedValue(OperationType.exposure) ||
      hasSignedValue(OperationType.warmth) ||
      hasSignedValue(OperationType.tint) ||
      hasSignedValue(OperationType.brightness)) {
    image = applyFusedColorBalanceOps(
      image,
      exposure: valueFor(OperationType.exposure),
      warmth: valueFor(OperationType.warmth),
      tint: valueFor(OperationType.tint),
      brightness: valueFor(OperationType.brightness),
    );
  }

  if (hasSignedValue(OperationType.highlights) ||
      hasSignedValue(OperationType.shadows) ||
      hasSignedValue(OperationType.contrast) ||
      hasPositiveValue(OperationType.blackpoint)) {
    image = applyFusedToneOps(
      image,
      highlights: valueFor(OperationType.highlights),
      shadows: valueFor(OperationType.shadows),
      contrast: valueFor(OperationType.contrast),
      blackpoint: valueFor(OperationType.blackpoint),
    );
  }

  if (hasSignedValue(OperationType.saturation) ||
      hasSignedValue(OperationType.vibrance)) {
    image = applyFusedChromaOps(
      image,
      saturation: valueFor(OperationType.saturation),
      vibrance: valueFor(OperationType.vibrance),
    );
  }

  if (hasSignedValue(OperationType.definition)) {
    image = applyDefinition(image, valueFor(OperationType.definition));
  }

  if (hasSignedValue(OperationType.sharpness)) {
    image = applySharpness(image, valueFor(OperationType.sharpness));
  }

  if (hasSignedValue(OperationType.vignette)) {
    image = applyVignette(image, valueFor(OperationType.vignette));
  }

  if (hasPositiveValue(OperationType.blur)) {
    image = applyBlur(image, valueFor(OperationType.blur));
  }

  if (hasPositiveValue(OperationType.grain) ||
      hasPositiveValue(OperationType.fade)) {
    image = applyFusedFinishOps(
      image,
      grain: valueFor(OperationType.grain),
      fade: valueFor(OperationType.fade),
    );
  }

  return image;
}

img.Image applySelectiveColorToImageSync({
  required img.Image image,
  required List<ColorEdit> colorEdits,
  color_ops.SelectiveColorPrepCache? selectiveColorPrepCache,
  Object? selectiveColorPrepCacheKey,
}) {
  image = ensureEditableImage(image);
  return color_ops.applyAllColorEdits(
    image,
    colorEdits,
    prepCache: selectiveColorPrepCache,
    prepCacheKey: selectiveColorPrepCacheKey,
  );
}

img.Image applyColorGradingToImageSync({
  required img.Image image,
  required List<ColorGradingEdit> colorGradingEdits,
  grading_ops.ColorGradingPrepCache? colorGradingPrepCache,
  Object? colorGradingPrepCacheKey,
}) {
  image = ensureEditableImage(image);
  return grading_ops.applyColorGrading(
    image,
    colorGradingEdits,
    prepCache: colorGradingPrepCache,
    prepCacheKey: colorGradingPrepCacheKey,
  );
}
