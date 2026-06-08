import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/export_settings.dart';

void main() {
  test('uses PNG export for PNG source paths', () {
    expect(imageFormatForPath('/photos/image.png'), ImageFormat.png);
    expect(imageFormatForPath('/photos/image.PNG'), ImageFormat.png);
  });

  test('uses JPG export for JPEG source paths', () {
    expect(imageFormatForPath('/photos/image.jpg'), ImageFormat.jpg);
    expect(imageFormatForPath('/photos/image.jpeg'), ImageFormat.jpg);
  });
}
