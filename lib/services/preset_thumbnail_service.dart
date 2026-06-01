import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/edit_pipeline/edit_pipeline.dart';
import '../domain/edit_pipeline/image_frame_codec.dart';
import '../model/editor_edit_state.dart';
import '../model/editor_preset.dart';
import '../model/rgba_image_frame.dart';

class PresetThumbnailService {
  const PresetThumbnailService();

  static const int thumbnailMaxDimension = 256;
  static const String defaultSourceAssetPath = 'assets/images/lenna.jpg';

  Future<RgbaImageFrame> loadDefaultSourceFrame() async {
    final data = await rootBundle.load(defaultSourceAssetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return compute(decodeRgbaImageFrame, Uint8List.fromList(bytes));
  }

  Future<Map<int, Uint8List>> buildThumbnails({
    required RgbaImageFrame originalFrame,
    required List<EditorPreset> presets,
  }) {
    return compute(_buildPresetThumbnailsSync, {
      'originalFrame': originalFrame.toMap(),
      'presets': [
        for (final preset in presets)
          {
            'id': preset.id,
            'stateJson': preset.state.activeOnly().toJsonString(),
          },
      ],
    });
  }
}

Map<int, Uint8List> _buildPresetThumbnailsSync(Map<String, Object> request) {
  final originalFrame = RgbaImageFrame.fromMap(
    Map<String, dynamic>.from(request['originalFrame'] as Map),
  );
  final thumbnailSource = resizeRgbaFrameToFit(
    originalFrame,
    maxDimension: PresetThumbnailService.thumbnailMaxDimension,
  );
  final presets = request['presets'] as List;
  final thumbnails = <int, Uint8List>{};

  for (final rawPreset in presets) {
    final preset = Map<String, dynamic>.from(rawPreset as Map);
    final state = EditorEditState.fromJsonString(preset['stateJson'] as String);
    final thumbnail = applyEditsToRgbaSync(
      originalFrame: copyRgbaImageFrame(thumbnailSource),
      edits: state.edits,
      colorEdits: state.colorEdits,
      colorGradingEdits: state.colorGradingEdits,
    );
    thumbnails[preset['id'] as int] = encodeJpgFromFrame(
      thumbnail,
      quality: 82,
    );
  }

  return thumbnails;
}
