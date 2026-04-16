import 'dart:typed_data';

class RgbaImageFrame {
  final Uint8List rgbaBytes;
  final int width;
  final int height;

  const RgbaImageFrame({
    required this.rgbaBytes,
    required this.width,
    required this.height,
  });

  Map<String, Object> toMap() => {
    'rgbaBytes': rgbaBytes,
    'width': width,
    'height': height,
  };

  factory RgbaImageFrame.fromMap(Map<String, dynamic> map) {
    return RgbaImageFrame(
      rgbaBytes: map['rgbaBytes'] as Uint8List,
      width: map['width'] as int,
      height: map['height'] as int,
    );
  }
}
