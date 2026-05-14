import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/export_settings.dart';
import 'package:licenta/services/export_service.dart';

void main() {
  test('original export preserves source dimensions and uses JPEG quality', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_export_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final sourceImage = _fixtureImage(width: 96, height: 64);
    final sourceFile = File('${tempDir.path}/source.png');
    await sourceFile.writeAsBytes(Uint8List.fromList(img.encodePng(sourceImage)));

    final service = ExportService();
    final progressValues = <double>[];
    final lowQuality = await service.encodeOriginal(
      originalImagePath: sourceFile.path,
      edits: [Edit(type: OperationType.exposure, value: 20)],
      colorEdits: const [],
      colorGradingEdits: const [],
      settings: const ExportSettings(format: ImageFormat.jpg, quality: 25),
    );
    final highQuality = await service.encodeOriginal(
      originalImagePath: sourceFile.path,
      edits: [Edit(type: OperationType.exposure, value: 20)],
      colorEdits: const [],
      colorGradingEdits: const [],
      settings: const ExportSettings(format: ImageFormat.jpg, quality: 95),
      onProgress: progressValues.add,
    );
    final decoded = img.decodeJpg(highQuality)!;

    expect(decoded.width, sourceImage.width);
    expect(decoded.height, sourceImage.height);
    expect(lowQuality.length, lessThan(highQuality.length));
    expect(progressValues, isNotEmpty);
    expect(progressValues.last, greaterThanOrEqualTo(0.95));
    for (var i = 1; i < progressValues.length; i++) {
      expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
    }
  });
}

img.Image _fixtureImage({required int width, required int height}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(
        x,
        y,
        (18 + x * 3 + y * 2).clamp(0, 255),
        (42 + x * 5 + y * 7).clamp(0, 255),
        (70 + x * 11 + y * 4).clamp(0, 255),
        255,
      );
    }
  }
  return image;
}
