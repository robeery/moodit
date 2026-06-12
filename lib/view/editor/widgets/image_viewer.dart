import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

class ImageViewer extends StatefulWidget {
  final ui.Image image;
  final ui.Image originalImage;
  final bool isLoading;

  const ImageViewer({
    super.key,
    required this.image,
    required this.originalImage,
    required this.isLoading,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  Timer? _originalViewTimer;
  bool _showingOriginal = false;

  @override
  void dispose() {
    _originalViewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        _originalViewTimer = Timer(const Duration(milliseconds: 300), () {
          setState(() => _showingOriginal = true);
        });
      },
      onLongPressEnd: (_) {
        _originalViewTimer?.cancel();
        setState(() => _showingOriginal = false);
      },
      onLongPressCancel: () {
        _originalViewTimer?.cancel();
        setState(() => _showingOriginal = false);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          RawImage(
            image: _showingOriginal ? widget.originalImage : widget.image,
            fit: BoxFit.contain,
          ),
          if (_showingOriginal)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.black54,
                child: Text('ORIGINAL', style: MooditType.monoMeta),
              ),
            ),
          if (widget.isLoading)
            const CircularProgressIndicator(
              color: MooditColors.baseAccent,
              strokeWidth: 1,
            ),
        ],
      ),
    );
  }
}
