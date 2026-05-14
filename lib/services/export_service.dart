import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import '../domain/edit_pipeline/edit_pipeline_stages.dart';
import '../domain/edit_pipeline/image_frame_codec.dart';
import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';
import '../model/edit.dart';
import '../model/export_settings.dart';

class ExportService {
  Future<void> saveToGallery({
    required String originalImagePath,
    required List<Edit> edits,
    required List<ColorEdit> colorEdits,
    required List<ColorGradingEdit> colorGradingEdits,
    required ExportSettings settings,
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0.0);
    final encoded = await encodeOriginal(
      originalImagePath: originalImagePath,
      edits: edits,
      colorEdits: colorEdits,
      colorGradingEdits: colorGradingEdits,
      settings: settings,
      onProgress: onProgress,
    );
    onProgress?.call(0.97);
    final name = 'edited_${DateTime.now().millisecondsSinceEpoch}.${settings.format.extension}';
    await Gal.putImageBytes(encoded, name: name);
    onProgress?.call(1.0);
  }

  Future<Uint8List> encodeOriginal({
    required String originalImagePath,
    required List<Edit> edits,
    required List<ColorEdit> colorEdits,
    required List<ColorGradingEdit> colorGradingEdits,
    required ExportSettings settings,
    ValueChanged<double>? onProgress,
  }) {
    final request = _OriginalExportRequest(
      originalImagePath: originalImagePath,
      edits: List<Edit>.of(edits),
      colorEdits: List<ColorEdit>.of(colorEdits),
      colorGradingEdits: List<ColorGradingEdit>.of(colorGradingEdits),
      settings: settings,
    );
    if (onProgress != null) {
      return _encodeOriginalWithProgress(request, onProgress);
    }

    return compute(
      _encodeOriginal,
      request,
    );
  }

  Future<Uint8List> _encodeOriginalWithProgress(
    _OriginalExportRequest request,
    ValueChanged<double> onProgress,
  ) async {
    final receivePort = ReceivePort();
    final completer = Completer<Uint8List>();
    late final StreamSubscription<dynamic> subscription;
    late final Isolate isolate;

    subscription = receivePort.listen((message) {
      if (message is _OriginalExportProgress) {
        onProgress(message.value);
        return;
      }
      if (message is _OriginalExportResult) {
        completer.complete(message.bytes);
        return;
      }
      if (message is _OriginalExportError) {
        completer.completeError(
          Exception(message.message),
          StackTrace.fromString(message.stackTrace),
        );
        return;
      }
      completer.completeError(Exception('Unexpected export isolate message'));
    });

    try {
      isolate = await Isolate.spawn(
        _encodeOriginalWithProgressEntry,
        _OriginalExportIsolateRequest(
          request: request,
          sendPort: receivePort.sendPort,
        ),
      );
    } catch (e) {
      receivePort.close();
      unawaited(subscription.cancel());
      rethrow;
    }

    try {
      return await completer.future;
    } finally {
      isolate.kill(priority: Isolate.immediate);
      receivePort.close();
      await subscription.cancel();
    }
  }
}

class _OriginalExportRequest {
  const _OriginalExportRequest({
    required this.originalImagePath,
    required this.edits,
    required this.colorEdits,
    required this.colorGradingEdits,
    required this.settings,
  });

  final String originalImagePath;
  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> colorGradingEdits;
  final ExportSettings settings;
}

Uint8List _encodeOriginal(_OriginalExportRequest request) {
  final image = _applyOriginalExportPipeline(request);
  return _encodeEditedImage(image, request.settings);
}

void _encodeOriginalWithProgressEntry(_OriginalExportIsolateRequest request) {
  void report(double value) {
    request.sendPort.send(_OriginalExportProgress(value));
  }

  try {
    final image = _applyOriginalExportPipeline(request.request, report);
    report(0.90);
    final encoded = _encodeEditedImage(image, request.request.settings);
    report(0.95);
    request.sendPort.send(_OriginalExportResult(encoded));
  } catch (e, stackTrace) {
    request.sendPort.send(_OriginalExportError(e.toString(), stackTrace.toString()));
  }
}

img.Image _applyOriginalExportPipeline(
  _OriginalExportRequest request, [
  void Function(double value)? report,
]) {
  report?.call(0.04);
  final originalBytes = File(request.originalImagePath).readAsBytesSync();
  report?.call(0.12);
  var image = decodeEditableImage(originalBytes);
  report?.call(0.24);

  image = applyBasicEditsToImageSync(
    image: image,
    edits: request.edits,
  );
  report?.call(0.45);

  image = applySelectiveColorToImageSync(
    image: image,
    colorEdits: request.colorEdits,
  );
  report?.call(0.68);

  image = applyColorGradingToImageSync(
    image: image,
    colorGradingEdits: request.colorGradingEdits,
  );
  report?.call(0.84);

  return image;
}

Uint8List _encodeEditedImage(img.Image image, ExportSettings settings) {
  switch (settings.format) {
    case ImageFormat.jpg:
      return Uint8List.fromList(
        img.encodeJpg(image, quality: settings.quality),
      );
    case ImageFormat.png:
      return Uint8List.fromList(img.encodePng(image));
  }
}

class _OriginalExportIsolateRequest {
  const _OriginalExportIsolateRequest({
    required this.request,
    required this.sendPort,
  });

  final _OriginalExportRequest request;
  final SendPort sendPort;
}

class _OriginalExportProgress {
  const _OriginalExportProgress(this.value);

  final double value;
}

class _OriginalExportResult {
  const _OriginalExportResult(this.bytes);

  final Uint8List bytes;
}

class _OriginalExportError {
  const _OriginalExportError(this.message, this.stackTrace);

  final String message;
  final String stackTrace;
}
