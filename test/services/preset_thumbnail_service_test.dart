import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/model/rgba_image_frame.dart';
import 'package:licenta/services/preset_thumbnail_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled default thumbnail source', () async {
    final frame = await const PresetThumbnailService().loadDefaultSourceFrame();

    expect(frame.width, 512);
    expect(frame.height, 512);
  });

  test('builds small encoded thumbnails for preset recipes', () async {
    final service = PresetThumbnailService();
    final preset = EditorPreset(
      id: 7,
      name: 'Brighter',
      state: EditorEditState(
        edits: [Edit(type: OperationType.brightness, value: 20)],
        colorEdits: const [],
        colorGradingEdits: const [],
      ),
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: DateTime.utc(2026, 6, 1),
    );

    final thumbnails = await service.buildThumbnails(
      originalFrame: _frame(width: 256, height: 128),
      presets: [preset],
    );
    final decoded = img.decodeJpg(thumbnails[7]!);

    expect(decoded, isNotNull);
    expect(decoded!.width, PresetThumbnailService.thumbnailMaxDimension);
    expect(decoded.height, 128);
  });

  test('builds png preset thumbnails when the source has transparency',
      () async {
    final service = PresetThumbnailService();
    final preset = EditorPreset(
      id: 8,
      name: 'Transparent',
      state: EditorEditState(
        edits: [Edit(type: OperationType.brightness, value: 20)],
        colorEdits: const [],
        colorGradingEdits: const [],
      ),
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: DateTime.utc(2026, 6, 1),
    );

    final thumbnails = await service.buildThumbnails(
      originalFrame: _frame(
        width: 16,
        height: 16,
        transparentPixel: true,
      ),
      presets: [preset],
    );
    final decoded = img.decodePng(thumbnails[8]!);

    expect(decoded, isNotNull);
    expect(decoded!.width, 16);
    expect(decoded.height, 16);
    expect(decoded.toUint8List()[((2 * 16 + 3) * 4) + 3], 0);
  });
}

RgbaImageFrame _frame({
  required int width,
  required int height,
  bool transparentPixel = false,
}) {
  final bytes = Uint8List(width * height * 4);
  for (var offset = 0; offset < bytes.length; offset += 4) {
    bytes[offset] = 60;
    bytes[offset + 1] = 100;
    bytes[offset + 2] = 140;
    bytes[offset + 3] = 255;
  }
  if (transparentPixel) {
    final offset = ((2 * width + 3) * 4);
    bytes[offset] = 220;
    bytes[offset + 1] = 30;
    bytes[offset + 2] = 180;
    bytes[offset + 3] = 0;
  }
  return RgbaImageFrame(
    rgbaBytes: bytes,
    width: width,
    height: height,
  );
}
