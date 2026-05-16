import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../model/rgba_image_frame.dart';

class PreviewImageDecoder {
  const PreviewImageDecoder();

  Future<PreviewImageInfo> readImageInfo(String imagePath) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(imagePath);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    try {
      return PreviewImageInfo(
        width: descriptor.width,
        height: descriptor.height,
      );
    } finally {
      descriptor.dispose();
      buffer.dispose();
    }
  }

  Future<RgbaImageFrame> decodeFromPath(
    String imagePath, {
    int maxDimension = 1080,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(imagePath);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    try {
      final size = _targetSize(
        width: descriptor.width,
        height: descriptor.height,
        maxDimension: maxDimension,
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: size.width,
        targetHeight: size.height,
      );

      try {
        final frame = await codec.getNextFrame();
        final image = frame.image;

        try {
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (byteData == null) {
            throw Exception('Failed to decode preview image');
          }
          final rgbaBytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );

          return RgbaImageFrame(
            rgbaBytes: Uint8List.fromList(rgbaBytes),
            width: image.width,
            height: image.height,
          );
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
      buffer.dispose();
    }
  }

  _PreviewImageSize _targetSize({
    required int width,
    required int height,
    required int maxDimension,
  }) {
    if (width <= maxDimension && height <= maxDimension) {
      return _PreviewImageSize(width: width, height: height);
    }

    final scale = maxDimension / math.max(width, height);
    return _PreviewImageSize(
      width: math.max(1, (width * scale).round()),
      height: math.max(1, (height * scale).round()),
    );
  }
}

class PreviewImageInfo {
  const PreviewImageInfo({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

class _PreviewImageSize {
  const _PreviewImageSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}
