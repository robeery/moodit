import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/services/preview_image_decoder.dart';

void main() {
  test('preview decoder downsizes without exceeding max dimension', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_preview_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final sourceImage = img.Image(width: 40, height: 20, numChannels: 4);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        sourceImage.setPixelRgba(x, y, 20 + x, 40 + y, 80, 255);
      }
    }

    final sourceFile = File('${tempDir.path}/source.png');
    await sourceFile.writeAsBytes(Uint8List.fromList(img.encodePng(sourceImage)));

    final frame = await const PreviewImageDecoder().decodeFromPath(
      sourceFile.path,
      maxDimension: 10,
    );

    expect(frame.width, 10);
    expect(frame.height, 5);
    expect(frame.rgbaBytes.length, frame.width * frame.height * 4);
  });
}
