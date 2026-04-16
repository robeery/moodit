import 'dart:typed_data';

import 'package:gal/gal.dart';
import '../domain/apply_edits.dart';
import '../model/export_settings.dart';
import '../model/rgba_image_frame.dart';

class ExportService {
  Future<void> saveToGallery(RgbaImageFrame frame, ExportSettings settings) async {
    final encoded = _encode(frame, settings);
    final name = 'edited_${DateTime.now().millisecondsSinceEpoch}.${settings.format.extension}';
    await Gal.putImageBytes(encoded, name: name);
  }

  Uint8List _encode(RgbaImageFrame frame, ExportSettings settings) {
    switch (settings.format) {
      case ImageFormat.jpg:
        return encodeJpgFromFrame(frame, quality: settings.quality);
      case ImageFormat.png:
        return encodePngFromFrame(frame);
    }
  }
}
