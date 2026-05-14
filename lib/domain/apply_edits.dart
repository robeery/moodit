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

RgbaImageFrame _copyFrame(RgbaImageFrame frame) {
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(frame.rgbaBytes),
    width: frame.width,
    height: frame.height,
  );
}

class EditPipelineStageCache {
  Object? _afterBasicKey;
  RgbaImageFrame? _afterBasicFrame;
  Object? _afterSelectiveKey;
  RgbaImageFrame? _afterSelectiveFrame;
  int _afterBasicBuildCount = 0;
  int _afterSelectiveBuildCount = 0;

  int get debugAfterBasicBuildCount => _afterBasicBuildCount;
  int get debugAfterSelectiveBuildCount => _afterSelectiveBuildCount;

  void clear() {
    _afterBasicKey = null;
    _afterBasicFrame = null;
    _afterSelectiveKey = null;
    _afterSelectiveFrame = null;
  }

  RgbaImageFrame? _afterBasicFor(Object? key) {
    final frame = _afterBasicFrame;
    if (frame == null || _afterBasicKey != key) return null;
    return _copyFrame(frame);
  }

  RgbaImageFrame? _afterSelectiveFor(Object? key) {
    final frame = _afterSelectiveFrame;
    if (frame == null || _afterSelectiveKey != key) return null;
    return _copyFrame(frame);
  }

  void _storeAfterBasic(Object? key, RgbaImageFrame frame) {
    if (_afterBasicKey != key) {
      _afterSelectiveKey = null;
      _afterSelectiveFrame = null;
    }
    _afterBasicKey = key;
    _afterBasicFrame = frame;
    _afterBasicBuildCount++;
  }

  void _storeAfterSelective(Object? key, RgbaImageFrame frame) {
    _afterSelectiveKey = key;
    _afterSelectiveFrame = frame;
    _afterSelectiveBuildCount++;
  }
}

img.Image applyBasicEditsToImageSync({
  required img.Image image,
  required List<Edit> edits,
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
  image = _ensureEditableImage(image);
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
  image = _ensureEditableImage(image);
  return grading_ops.applyColorGrading(
    image,
    colorGradingEdits,
    prepCache: colorGradingPrepCache,
    prepCacheKey: colorGradingPrepCacheKey,
  );
}

img.Image applyEditsToImageSync({
  required img.Image image,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
  color_ops.SelectiveColorPrepCache? selectiveColorPrepCache,
  Object? selectiveColorPrepCacheKey,
  grading_ops.ColorGradingPrepCache? colorGradingPrepCache,
  Object? colorGradingPrepCacheKey,
}) {
  image = applyBasicEditsToImageSync(image: image, edits: edits);
  image = applySelectiveColorToImageSync(
    image: image,
    colorEdits: colorEdits,
    selectiveColorPrepCache: selectiveColorPrepCache,
    selectiveColorPrepCacheKey: selectiveColorPrepCacheKey,
  );
  image = applyColorGradingToImageSync(
    image: image,
    colorGradingEdits: colorGradingEdits,
    colorGradingPrepCache: colorGradingPrepCache,
    colorGradingPrepCacheKey: colorGradingPrepCacheKey,
  );
  return image;
}

RgbaImageFrame applyEditsToRgbaSync({
  required RgbaImageFrame originalFrame,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
  color_ops.SelectiveColorPrepCache? selectiveColorPrepCache,
  Object? selectiveColorPrepCacheKey,
  grading_ops.ColorGradingPrepCache? colorGradingPrepCache,
  Object? colorGradingPrepCacheKey,
}) {
  final result = applyEditsToImageSync(
    image: imageFromRgbaFrame(originalFrame),
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
    selectiveColorPrepCache: selectiveColorPrepCache,
    selectiveColorPrepCacheKey: selectiveColorPrepCacheKey,
    colorGradingPrepCache: colorGradingPrepCache,
    colorGradingPrepCacheKey: colorGradingPrepCacheKey,
  );
  return frameFromImage(result);
}

RgbaImageFrame applyEditsToRgbaWithStageCacheSync({
  required RgbaImageFrame originalFrame,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
  required EditPipelineStageCache stageCache,
  required Object? basicStageCacheKey,
  required Object? selectiveStageCacheKey,
  color_ops.SelectiveColorPrepCache? selectiveColorPrepCache,
  Object? selectiveColorPrepCacheKey,
  grading_ops.ColorGradingPrepCache? colorGradingPrepCache,
  Object? colorGradingPrepCacheKey,
}) {
  final cachedAfterSelective = stageCache._afterSelectiveFor(
    selectiveStageCacheKey,
  );
  if (cachedAfterSelective != null) {
    final result = applyColorGradingToImageSync(
      image: imageFromRgbaFrame(cachedAfterSelective),
      colorGradingEdits: colorGradingEdits,
      colorGradingPrepCache: colorGradingPrepCache,
      colorGradingPrepCacheKey: colorGradingPrepCacheKey,
    );
    return frameFromImage(result);
  }

  final cachedAfterBasic = stageCache._afterBasicFor(basicStageCacheKey);
  late img.Image image;

  if (cachedAfterBasic != null) {
    image = imageFromRgbaFrame(cachedAfterBasic);
  } else {
    image = applyBasicEditsToImageSync(
      image: imageFromRgbaFrame(_copyFrame(originalFrame)),
      edits: edits,
    );
    stageCache._storeAfterBasic(basicStageCacheKey, frameFromImage(image));
  }

  image = applySelectiveColorToImageSync(
    image: image,
    colorEdits: colorEdits,
    selectiveColorPrepCache: selectiveColorPrepCache,
    selectiveColorPrepCacheKey: selectiveColorPrepCacheKey,
  );
  stageCache._storeAfterSelective(selectiveStageCacheKey, frameFromImage(image));

  image = applyColorGradingToImageSync(
    image: image,
    colorGradingEdits: colorGradingEdits,
    colorGradingPrepCache: colorGradingPrepCache,
    colorGradingPrepCacheKey: colorGradingPrepCacheKey,
  );
  return frameFromImage(image);
}

Uint8List applyEditsSync({
  required Uint8List originalBytes,
  required List<Edit> edits,
  required List<ColorEdit> colorEdits,
  required List<ColorGradingEdit> colorGradingEdits,
  color_ops.SelectiveColorPrepCache? selectiveColorPrepCache,
  Object? selectiveColorPrepCacheKey,
  grading_ops.ColorGradingPrepCache? colorGradingPrepCache,
  Object? colorGradingPrepCacheKey,
}) {
  final result = applyEditsToImageSync(
    image: _decodeEditableImage(originalBytes),
    edits: edits,
    colorEdits: colorEdits,
    colorGradingEdits: colorGradingEdits,
    selectiveColorPrepCache: selectiveColorPrepCache,
    selectiveColorPrepCacheKey: selectiveColorPrepCacheKey,
    colorGradingPrepCache: colorGradingPrepCache,
    colorGradingPrepCacheKey: colorGradingPrepCacheKey,
  );
  return Uint8List.fromList(img.encodeJpg(result));
}
