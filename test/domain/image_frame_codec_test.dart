import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/domain/edit_pipeline/image_frame_codec.dart';
import 'package:licenta/model/rgba_image_frame.dart';

void main() {
  test('resizeRgbaFrameToFit preserves aspect ratio within max dimension', () {
    final frame = RgbaImageFrame(
      width: 512,
      height: 256,
      rgbaBytes: Uint8List(512 * 256 * 4),
    );

    final resized = resizeRgbaFrameToFit(frame, maxDimension: 256);

    expect(resized.width, 256);
    expect(resized.height, 128);
    expect(resized.rgbaBytes.length, 256 * 128 * 4);
  });
}
