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

RgbaImageFrame copyRgbaImageFrame(RgbaImageFrame frame) {
  return RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(frame.rgbaBytes),
    width: frame.width,
    height: frame.height,
  );
}
