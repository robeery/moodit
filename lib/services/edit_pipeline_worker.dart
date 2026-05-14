import 'dart:async';
import 'dart:isolate';

import '../domain/color_grading_operations.dart' as grading_ops;
import '../domain/color_operations.dart' as color_ops;
import '../domain/edit_pipeline/edit_pipeline.dart';
import '../domain/edit_pipeline/edit_pipeline_cache_keys.dart';
import '../domain/edit_pipeline/edit_pipeline_stage_cache.dart';
import '../model/color_edit.dart';
import '../model/color_grading_edit.dart';
import '../model/edit.dart';
import '../model/rgba_image_frame.dart';

class EditPipelineWorker {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _subscription;
  SendPort? _workerPort;
  Future<void>? _startFuture;
  final Map<int, Completer<Object?>> _pendingRequests = {};
  int _nextRequestId = 1;
  bool _disposed = false;

  Future<void> loadOriginalFrame(RgbaImageFrame frame) async {
    _assertNotDisposed();
    await _sendRequest('loadOriginalFrame', {
      'frame': _frameToMessage(frame),
    });
  }

  Future<RgbaImageFrame> process({
    required List<Edit> edits,
    required List<ColorEdit> colorEdits,
    required List<ColorGradingEdit> colorGradingEdits,
  }) async {
    _assertNotDisposed();
    final result = await _sendRequest('process', {
      'edits': List<Edit>.of(edits),
      'colorEdits': List<ColorEdit>.of(colorEdits),
      'colorGradingEdits': List<ColorGradingEdit>.of(colorGradingEdits),
    });
    return _frameFromMessage(result as Map<String, dynamic>);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Edit pipeline worker was disposed'));
      }
    }
    _pendingRequests.clear();

    _subscription?.cancel();
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _subscription = null;
    _receivePort = null;
    _isolate = null;
    _workerPort = null;
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError('Edit pipeline worker has been disposed');
    }
  }

  Future<Object?> _sendRequest(String command, Map<String, Object?> payload) async {
    await _ensureStarted();
    final workerPort = _workerPort;
    if (workerPort == null) {
      throw StateError('Edit pipeline worker did not start');
    }

    final id = _nextRequestId++;
    final completer = Completer<Object?>();
    _pendingRequests[id] = completer;
    workerPort.send({
      'id': id,
      'command': command,
      ...payload,
    });
    return completer.future;
  }

  Future<void> _ensureStarted() {
    if (_workerPort != null) return Future.value();
    return _startFuture ??= _start();
  }

  Future<void> _start() async {
    final ready = Completer<SendPort>();
    final receivePort = ReceivePort();
    _receivePort = receivePort;
    _subscription = receivePort.listen((message) {
      if (message is SendPort) {
        _workerPort = message;
        if (!ready.isCompleted) ready.complete(message);
        return;
      }
      _handleWorkerResponse(message);
    });

    _isolate = await Isolate.spawn(
      _editPipelineWorkerMain,
      receivePort.sendPort,
      debugName: 'edit_pipeline_worker',
    );
    await ready.future;
  }

  void _handleWorkerResponse(Object? message) {
    if (message is! Map) return;
    final id = message['id'] as int?;
    if (id == null) return;
    final completer = _pendingRequests.remove(id);
    if (completer == null || completer.isCompleted) return;

    if (message['ok'] == true) {
      completer.complete(message['result']);
      return;
    }

    final error = message['error'] as String? ?? 'Unknown worker error';
    final stackTrace = message['stackTrace'] as String?;
    completer.completeError(
      StateError(error),
      stackTrace == null ? StackTrace.current : StackTrace.fromString(stackTrace),
    );
  }
}

Map<String, Object> _frameToMessage(RgbaImageFrame frame) => {
  'rgbaBytes': TransferableTypedData.fromList([frame.rgbaBytes]),
  'width': frame.width,
  'height': frame.height,
};

RgbaImageFrame _frameFromMessage(Map<String, dynamic> message) {
  final rgbaBytes = (message['rgbaBytes'] as TransferableTypedData)
      .materialize()
      .asUint8List();
  return RgbaImageFrame(
    rgbaBytes: rgbaBytes,
    width: message['width'] as int,
    height: message['height'] as int,
  );
}

@pragma('vm:entry-point')
void _editPipelineWorkerMain(SendPort mainPort) {
  final receivePort = ReceivePort();
  final worker = _EditPipelineWorkerIsolate(mainPort);
  mainPort.send(receivePort.sendPort);
  receivePort.listen(worker.handleMessage);
}

class _EditPipelineWorkerIsolate {
  _EditPipelineWorkerIsolate(this._mainPort);

  final SendPort _mainPort;
  final color_ops.SelectiveColorPrepCache _selectiveColorPrepCache =
      color_ops.SelectiveColorPrepCache();
  final grading_ops.ColorGradingPrepCache _colorGradingPrepCache =
      grading_ops.ColorGradingPrepCache();
  final EditPipelineStageCache _stageCache = EditPipelineStageCache();
  RgbaImageFrame? _originalFrame;
  int _originalFrameRevision = 0;

  void handleMessage(Object? message) {
    if (message is! Map) return;
    final id = message['id'] as int?;
    final command = message['command'] as String?;
    if (id == null || command == null) return;

    try {
      switch (command) {
        case 'loadOriginalFrame':
          _originalFrame = _frameFromMessage(
            message['frame'] as Map<String, dynamic>,
          );
          _originalFrameRevision++;
          _stageCache.clear();
          _selectiveColorPrepCache.clear();
          _colorGradingPrepCache.clear();
          _sendSuccess(id);
        case 'process':
          final originalFrame = _originalFrame;
          if (originalFrame == null) {
            throw StateError('No original frame loaded in edit pipeline worker');
          }
          final edits = message['edits'] as List<Edit>;
          final colorEdits = message['colorEdits'] as List<ColorEdit>;
          final colorGradingEdits =
              message['colorGradingEdits'] as List<ColorGradingEdit>;
          final basicStageKey = buildBasicStageCacheKey(
            originalFrameRevision: _originalFrameRevision,
            edits: edits,
          );
          final selectiveStageKey = buildSelectiveStageCacheKey(
            basicStageCacheKey: basicStageKey,
            colorEdits: colorEdits,
          );
          final result = applyEditsToRgbaWithStageCacheSync(
            originalFrame: originalFrame,
            edits: edits,
            colorEdits: colorEdits,
            colorGradingEdits: colorGradingEdits,
            stageCache: _stageCache,
            basicStageCacheKey: basicStageKey,
            selectiveStageCacheKey: selectiveStageKey,
            selectiveColorPrepCache: _selectiveColorPrepCache,
            selectiveColorPrepCacheKey: basicStageKey,
            colorGradingPrepCache: _colorGradingPrepCache,
            colorGradingPrepCacheKey: selectiveStageKey,
          );
          _sendSuccess(id, _frameToMessage(result));
        default:
          throw StateError('Unknown edit pipeline worker command: $command');
      }
    } catch (error, stackTrace) {
      _mainPort.send({
        'id': id,
        'ok': false,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
    }
  }

  void _sendSuccess(int id, [Object? result]) {
    _mainPort.send({
      'id': id,
      'ok': true,
      'result': result,
    });
  }
}
