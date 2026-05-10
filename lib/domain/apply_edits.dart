import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';
import '../model/edit.dart';
import '../model/rgba_image_frame.dart';
import 'color_grading_operations.dart' as grading_ops;
import 'color_operations.dart' as color_ops;
import 'image_operations.dart';

img.Image _ensureEditableImage(img.Image image) {
  if (image.hasPalette ||
      image.format != img.Format.uint8 ||
      image.numChannels != 4) {
    return image.convert(format: img.Format.uint8, numChannels: 4);
  }
  return image;
}

img.Image _decodeEditableImage(Uint8List originalBytes) {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }
  return _ensureEditableImage(decoded);
}

img.Image imageFromRgbaFrame(RgbaImageFrame frame) {
  return img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.rgbaBytes.buffer,
    bytesOffset: frame.rgbaBytes.offsetInBytes,
    rowStride: frame.width * 4,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

RgbaImageFrame frameFromImage(img.Image image) {
  final normalized = _ensureEditableImage(image);
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(normalized.toUint8List()),
    width: normalized.width,
    height: normalized.height,
  );
}

RgbaImageFrame decodeRgbaImageFrame(Uint8List originalBytes) {
  return frameFromImage(_decodeEditableImage(originalBytes));
}

Uint8List encodeJpgFromFrame(RgbaImageFrame frame, {int quality = 90}) {
  return Uint8List.fromList(
    img.encodeJpg(imageFromRgbaFrame(frame), quality: quality),
  );
}

Uint8List encodePngFromFrame(RgbaImageFrame frame) {
  return Uint8List.fromList(img.encodePng(imageFromRgbaFrame(frame)));
}

img.Image applyEditsToImageSync({
  required img.Image image,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
}) {
  image = _ensureEditableImage(image);

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

  if (hasPositiveValue(OperationType.grain)) {
    image = applyGrain(image, valueFor(OperationType.grain));
  }

  if (hasPositiveValue(OperationType.fade)) {
    image = applyFade(image, valueFor(OperationType.fade));
  }

  image = color_ops.applyAllColorEdits(image, colorEdits);
  image = grading_ops.applyColorGrading(image, colorGradingEdits);
  return image;
}

RgbaImageFrame applyEditsToRgbaSync({
  required RgbaImageFrame originalFrame,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
}) {
  final result = applyEditsToImageSync(
    image: imageFromRgbaFrame(originalFrame),
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
  );
  return frameFromImage(result);
}

Uint8List applyEditsSync({
  required Uint8List originalBytes,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
}) {
  final result = applyEditsToImageSync(
    image: _decodeEditableImage(originalBytes),
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
  );
  return Uint8List.fromList(img.encodeJpg(result));
}
