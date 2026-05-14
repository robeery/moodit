import '../../model/rgba_image_frame.dart';
import 'image_frame_codec.dart';

class EditPipelineStageCache {
  Object? _afterBasicKey;
  RgbaImageFrame? _afterBasicFrame;
  Object? _afterSelectiveKey;
  RgbaImageFrame? _afterSelectiveFrame;
  int _afterBasicBuildCount = 0;
  int _afterSelectiveBuildCount = 0;

  int get debugAfterBasicBuildCount => _afterBasicBuildCount;
  int get debugAfterSelectiveBuildCount => _afterSelectiveBuildCount;

  void clear() {
    _afterBasicKey = null;
    _afterBasicFrame = null;
    _afterSelectiveKey = null;
    _afterSelectiveFrame = null;
  }

  RgbaImageFrame? afterBasicFor(Object? key) {
    final frame = _afterBasicFrame;
    if (frame == null || _afterBasicKey != key) return null;
    return copyRgbaImageFrame(frame);
  }

  RgbaImageFrame? afterSelectiveFor(Object? key) {
    final frame = _afterSelectiveFrame;
    if (frame == null || _afterSelectiveKey != key) return null;
    return copyRgbaImageFrame(frame);
  }

  void storeAfterBasic(Object? key, RgbaImageFrame frame) {
    if (_afterBasicKey != key) {
      _afterSelectiveKey = null;
      _afterSelectiveFrame = null;
    }
    _afterBasicKey = key;
    _afterBasicFrame = frame;
    _afterBasicBuildCount++;
  }

  void storeAfterSelective(Object? key, RgbaImageFrame frame) {
    _afterSelectiveKey = key;
    _afterSelectiveFrame = frame;
    _afterSelectiveBuildCount++;
  }
}
