enum ImageFormat {
  jpg('JPG', 'jpg'),
  png('PNG', 'png');

  final String label;
  final String extension;
  const ImageFormat(this.label, this.extension);
}

ImageFormat imageFormatForPath(String path) {
  return path.toLowerCase().endsWith('.png')
      ? ImageFormat.png
      : ImageFormat.jpg;
}

class ExportSettings {
  final ImageFormat format;
  final int quality;

  const ExportSettings({
    this.format = ImageFormat.jpg,
    this.quality = 100,
  });

  ExportSettings copyWith({ImageFormat? format, int? quality}) {
    return ExportSettings(
      format: format ?? this.format,
      quality: quality ?? this.quality,
    );
  }
}
