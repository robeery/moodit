import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../model/color_edit.dart';
import '../../model/color_grading_edit.dart';
import '../../model/edit.dart';
import '../../model/rgba_image_frame.dart';
import '../color_grading_operations.dart' as grading_ops;
import '../color_operations.dart' as color_ops;
import 'edit_pipeline_stage_cache.dart';
import 'edit_pipeline_stages.dart';
import 'image_frame_codec.dart';

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
  final cachedAfterSelective = stageCache.afterSelectiveFor(
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

  final cachedAfterBasic = stageCache.afterBasicFor(basicStageCacheKey);
  late img.Image image;

  if (cachedAfterBasic != null) {
    image = imageFromRgbaFrame(cachedAfterBasic);
  } else {
    image = applyBasicEditsToImageSync(
      image: imageFromRgbaFrame(copyRgbaImageFrame(originalFrame)),
      edits: edits,
    );
    stageCache.storeAfterBasic(basicStageCacheKey, frameFromImage(image));
  }

  image = applySelectiveColorToImageSync(
    image: image,
    colorEdits: colorEdits,
    selectiveColorPrepCache: selectiveColorPrepCache,
    selectiveColorPrepCacheKey: selectiveColorPrepCacheKey,
  );
  stageCache.storeAfterSelective(selectiveStageCacheKey, frameFromImage(image));

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
    image: decodeEditableImage(originalBytes),
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
