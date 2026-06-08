import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../model/rgba_image_frame.dart';

img.Image ensureEditableImage(img.Image image) {
  if (image.hasPalette ||
      image.format != img.Format.uint8 ||
      image.numChannels != 4) {
    return image.convert(format: img.Format.uint8, numChannels: 4);
  }
  return image;
}

img.Image decodeEditableImage(Uint8List originalBytes) {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }
  return ensureEditableImage(decoded);
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
  final normalized = ensureEditableImage(image);
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(normalized.toUint8List()),
    width: normalized.width,
    height: normalized.height,
  );
}

RgbaImageFrame restoreTransparentPixels(
  RgbaImageFrame frame,
  RgbaImageFrame originalFrame,
) {
  assert(frame.rgbaBytes.length == originalFrame.rgbaBytes.length);
  for (var i = 0; i < frame.rgbaBytes.length; i += 4) {
    final originalAlpha = originalFrame.rgbaBytes[i + 3];
    frame.rgbaBytes[i + 3] = originalAlpha;
    if (originalAlpha != 0) continue;

    // PNG transparency case.
    frame.rgbaBytes[i] = originalFrame.rgbaBytes[i];
    frame.rgbaBytes[i + 1] = originalFrame.rgbaBytes[i + 1];
    frame.rgbaBytes[i + 2] = originalFrame.rgbaBytes[i + 2];
  }
  return frame;
}

RgbaImageFrame decodeRgbaImageFrame(Uint8List originalBytes) {
  return frameFromImage(decodeEditableImage(originalBytes));
}

Uint8List encodeJpgFromFrame(RgbaImageFrame frame, {int quality = 90}) {
  return Uint8List.fromList(
    img.encodeJpg(imageFromRgbaFrame(frame), quality: quality),
  );
}

Uint8List encodePngFromFrame(RgbaImageFrame frame) {
  return Uint8List.fromList(img.encodePng(imageFromRgbaFrame(frame)));
}

RgbaImageFrame resizeRgbaFrameToFit(
  RgbaImageFrame frame, {
  required int maxDimension,
}) {
  if (frame.width <= maxDimension && frame.height <= maxDimension) {
    return copyRgbaImageFrame(frame);
  }

  final scale = maxDimension / math.max(frame.width, frame.height);
  final resized = img.copyResize(
    imageFromRgbaFrame(frame),
    width: math.max(1, (frame.width * scale).round()),
    height: math.max(1, (frame.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
  return frameFromImage(resized);
}

RgbaImageFrame copyRgbaImageFrame(RgbaImageFrame frame) {
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(frame.rgbaBytes),
    width: frame.width,
    height: frame.height,
  );
}
