import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// Square preview box used in project/preset lists and detail headers. Falls
// back to an icon when there is no image.
class ThumbnailTile extends StatelessWidget {
  const ThumbnailTile({
    super.key,
    this.image,
    this.size = 60,
    this.fallbackIcon = Icons.image_outlined,
  });

  final ImageProvider? image;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final source = image;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: MooditColors.card,
        borderRadius: BorderRadius.circular(MooditDims.controlRadius),
        border: Border.all(color: MooditColors.hairline),
      ),
      child: source == null
          ? Icon(fallbackIcon, color: MooditColors.textOff, size: size * 0.34)
          : Image(image: source, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

// Builds a FileImage only when the path points to a real file.
ImageProvider? fileThumbnailProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}
