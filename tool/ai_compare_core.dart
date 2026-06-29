// benchmark tool for token "study"
//
// For one image + one prompt it records two paths:
// A) Moodit app flow: GPT returns edit parameters as JSON, then the local
//    pipeline applies them on the original image
// B) Direct Image API edit: /v1/images/edits returns a synthesized image
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

import 'package:licenta/domain/ai_provider.dart';
import 'package:licenta/domain/edit_pipeline/edit_pipeline.dart';
import 'package:licenta/domain/parse_edits_json.dart';
import 'package:licenta/model/editor_edit_state.dart';

const int _previewMaxDimension = 1080;
const String _defaultParamModel = 'gpt-5.5';
const String _defaultImageModel = 'gpt-image-2';
const String _defaultImageQuality = 'high';
const String _defaultImageSize = 'max-valid';
const String _defaultOutputFormat = 'same';
const int _imageEditSizeStep = 16;
const int _imageEditMaxEdge = 3840;
const int _imageEditMinPixels = 655360;
const int _imageEditMaxPixels = 8294400;

final Uri _responsesUrl = Uri.parse('https://api.openai.com/v1/responses');
final Uri _imageEditsUrl = Uri.parse('https://api.openai.com/v1/images/edits');

Future<void> runComparison(List<String> args) async {
  final options = _Options.parse(args);
  if (options.showHelp) {
    print(_usage);
    return;
  }

  final apiKey = _readApiKey();
  if (apiKey == null) {
    stderr.writeln('No API key. Set OPENAI_API_KEY or put it in .env.');
    exit(78);
  }

  final imageFile = File(options.imagePath);
  final originalBytes = await imageFile.readAsBytes();
  final original = img.decodeImage(originalBytes);
  if (original == null) {
    stderr.writeln('Could not decode image: ${options.imagePath}');
    exit(65);
  }

  final outDir = Directory(options.outDir ?? _defaultOutDir(options.imagePath));
  await outDir.create(recursive: true);
  final imageEditOptions = _resolveImageEditOptions(
    options: options,
    imagePath: options.imagePath,
    original: original,
  );

  print('Image        : ${options.imagePath} (${original.width}x${original.height})');
  print('Prompt       : ${options.prompt}');
  print('Path A model : ${options.paramModel}');
  print('Path A sent  : ${options.aFullRes ? "original" : "preview 1080px"}');
  print('Path B model : ${options.imageModel}');
  print('Path B opts  : quality=${options.imageQuality}, '
      'size=${imageEditOptions.size}, format=${imageEditOptions.outputFormat}');
  if (imageEditOptions.note != null) {
    print('Path B note  : ${imageEditOptions.note}');
  }
  print('Out          : ${outDir.path}\n');

  final pathA = options.runPathA
      ? await _runAppFlow(
          apiKey: apiKey,
          model: options.paramModel,
          prompt: options.prompt,
          original: original,
          sendFullRes: options.aFullRes,
          outDir: outDir,
        )
      : _skippedResult(
          label: 'A) Moodit app flow',
          sentResolution: options.aFullRes ? 'skipped (original)' : 'skipped (preview)',
          note: 'skipped by --only-b',
        );

  final pathB = options.runPathB
      ? await _runImageEdit(
          apiKey: apiKey,
          model: options.imageModel,
          prompt: options.prompt,
          imagePath: options.imagePath,
          imageBytes: originalBytes,
          original: original,
          quality: options.imageQuality,
          size: imageEditOptions.size,
          outputFormat: imageEditOptions.outputFormat,
          outputExtension: imageEditOptions.outputExtension,
          outDir: outDir,
        )
      : _skippedResult(
          label: 'B) Image API edit',
          sentResolution: 'skipped',
          note: 'skipped by --only-a',
        );

  final report = _buildReport(options, imageEditOptions, pathA, pathB);
  print('\n$report');
  await File('${outDir.path}/report.txt').writeAsString(report);
  await File('${outDir.path}/summary.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'image_path': options.imagePath,
      'prompt': options.prompt,
      'run_path_a': options.runPathA,
      'run_path_b': options.runPathB,
      'path_b_request_options': imageEditOptions.toJson(),
      'path_a': pathA.toJson(),
      'path_b': pathB.toJson(),
    }),
  );
}

class _Options {
  final String imagePath;
  final String prompt;
  final String paramModel;
  final String imageModel;
  final String imageQuality;
  final String imageSize;
  final String outputFormat;
  final String? outDir;
  final bool aFullRes;
  final bool runPathA;
  final bool runPathB;
  final bool showHelp;

  _Options({
    required this.imagePath,
    required this.prompt,
    required this.paramModel,
    required this.imageModel,
    required this.imageQuality,
    required this.imageSize,
    required this.outputFormat,
    required this.outDir,
    required this.aFullRes,
    required this.runPathA,
    required this.runPathB,
    required this.showHelp,
  });

  factory _Options.parse(List<String> args) {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      return _Options._help();
    }
    if (args.length < 2) {
      stderr.writeln(_usage);
      exit(64);
    }

    final positional = <String>[];
    var paramModel = _defaultParamModel;
    var imageModel = _defaultImageModel;
    var imageQuality = _defaultImageQuality;
    var imageSize = _defaultImageSize;
    var outputFormat = _defaultOutputFormat;
    String? outDir;
    var aFullRes = false;
    var onlyA = false;
    var onlyB = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--only-a':
          onlyA = true;
        case '--only-b':
          onlyB = true;
        case '--a-full-res':
          aFullRes = true;
        case '--a-preview':
          aFullRes = false;
        case '--param-model':
          paramModel = _readFlagValue(args, ++i, arg);
        case '--image-model':
          imageModel = _readFlagValue(args, ++i, arg);
        case '--quality':
          imageQuality = _readFlagValue(args, ++i, arg);
        case '--size':
          imageSize = _readFlagValue(args, ++i, arg);
        case '--output-format':
          outputFormat = _readFlagValue(args, ++i, arg);
        case '--out-dir':
          outDir = _readFlagValue(args, ++i, arg);
        default:
          if (arg.startsWith('--')) {
            stderr.writeln('Unknown option: $arg\n');
            stderr.writeln(_usage);
            exit(64);
          }
          positional.add(arg);
      }
    }

    if (onlyA && onlyB) {
      stderr.writeln('Use only one of --only-a or --only-b.');
      exit(64);
    }

    if (positional.length < 2) {
      stderr.writeln(_usage);
      exit(64);
    }
    if (positional.length > 2) {
      stderr.writeln('Too many positional arguments: ${positional.skip(2).join(" ")}');
      stderr.writeln(_usage);
      exit(64);
    }

    return _Options(
      imagePath: positional[0],
      prompt: positional[1],
      paramModel: paramModel,
      imageModel: imageModel,
      imageQuality: imageQuality,
      imageSize: imageSize,
      outputFormat: outputFormat,
      outDir: outDir,
      aFullRes: aFullRes,
      runPathA: !onlyB,
      runPathB: !onlyA,
      showHelp: false,
    );
  }

  factory _Options._help() => _Options(
        imagePath: '',
        prompt: '',
        paramModel: _defaultParamModel,
        imageModel: _defaultImageModel,
        imageQuality: _defaultImageQuality,
        imageSize: _defaultImageSize,
        outputFormat: _defaultOutputFormat,
        outDir: null,
        aFullRes: false,
        runPathA: true,
        runPathB: true,
        showHelp: true,
      );
}

class _Result {
  final String label;
  final String sentResolution;
  final int? inputTokens;
  final int? inputImageTokens;
  final int? inputTextTokens;
  final int? outputTokens;
  final int? outputImageTokens;
  final int? outputTextTokens;
  final int? totalTokens;
  final Duration latency;
  final String outputFile;
  final String responseFile;
  final String? note;
  final Map<String, dynamic>? usageRaw;

  _Result({
    required this.label,
    required this.sentResolution,
    required this.inputTokens,
    required this.inputImageTokens,
    required this.inputTextTokens,
    required this.outputTokens,
    required this.outputImageTokens,
    required this.outputTextTokens,
    required this.totalTokens,
    required this.latency,
    required this.outputFile,
    required this.responseFile,
    this.note,
    this.usageRaw,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'sent_resolution': sentResolution,
        'latency_ms': latency.inMilliseconds,
        'output_file': outputFile,
        'response_file': responseFile,
        'note': note,
        'tokens': {
          'input': inputTokens,
          'input_image': inputImageTokens,
          'input_text': inputTextTokens,
          'output': outputTokens,
          'output_image': outputImageTokens,
          'output_text': outputTextTokens,
          'total': totalTokens,
        },
        'usage_raw': usageRaw,
  };
}

class _ResolvedImageEditOptions {
  final String size;
  final String outputFormat;
  final String outputExtension;
  final String? note;

  _ResolvedImageEditOptions({
    required this.size,
    required this.outputFormat,
    required this.outputExtension,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'output_format': outputFormat,
        'output_extension': outputExtension,
        'note': note,
      };
}

class _ImageEditSize {
  final int width;
  final int height;

  _ImageEditSize(this.width, this.height);

  int get pixels => width * height;

  String get value => '${width}x$height';
}

_ResolvedImageEditOptions _resolveImageEditOptions({
  required _Options options,
  required String imagePath,
  required img.Image original,
}) {
  final noteParts = <String>[];
  final size = switch (options.imageSize) {
    'same' => '${original.width}x${original.height}',
    'max-valid' => _closestAcceptedImageEditSize(original).value,
    _ => options.imageSize,
  };
  final format = options.outputFormat == 'same'
      ? _formatFromPath(imagePath)
      : _normalizeOutputFormat(options.outputFormat);
  final extension = options.outputFormat == 'same'
      ? _extensionFromPath(imagePath, fallbackFormat: format)
      : _extensionForFormat(format);

  if (options.imageSize == 'same') {
    noteParts.add('output size follows input resolution exactly');
  } else if (options.imageSize == 'max-valid') {
    final originalSize = '${original.width}x${original.height}';
    if (size == originalSize) {
      noteParts.add('input resolution already satisfies gpt-image-2 constraints');
    } else {
      noteParts.add('output size adjusted from $originalSize to $size '
          'for gpt-image-2 constraints');
    }
  }
  if (options.outputFormat == 'same') {
    noteParts.add('output format follows input file extension');
  }

  return _ResolvedImageEditOptions(
    size: size,
    outputFormat: format,
    outputExtension: extension,
    note: noteParts.isEmpty ? null : noteParts.join('; '),
  );
}

_ImageEditSize _closestAcceptedImageEditSize(img.Image original) {
  final originalWidth = original.width;
  final originalHeight = original.height;
  final originalPixels = originalWidth * originalHeight;
  final longestEdge = math.max(originalWidth, originalHeight);

  var targetScale = 1.0;
  if (longestEdge > _imageEditMaxEdge) {
    targetScale = math.min(targetScale, _imageEditMaxEdge / longestEdge);
  }
  final pixelsAfterEdgeScale = originalPixels * targetScale * targetScale;
  if (pixelsAfterEdgeScale > _imageEditMaxPixels) {
    targetScale = math.min(
      targetScale,
      math.sqrt(_imageEditMaxPixels / originalPixels),
    );
  } else if (pixelsAfterEdgeScale < _imageEditMinPixels) {
    targetScale = math.max(
      targetScale,
      math.sqrt(_imageEditMinPixels / originalPixels),
    );
  }

  final targetWidth = originalWidth * targetScale;
  final targetHeight = originalHeight * targetScale;
  final targetPixels = targetWidth * targetHeight;
  final targetRatio = originalWidth / originalHeight;

  _ImageEditSize? best;
  var bestScore = double.infinity;

  for (var width = _imageEditSizeStep;
      width <= _imageEditMaxEdge;
      width += _imageEditSizeStep) {
    for (var height = _imageEditSizeStep;
        height <= _imageEditMaxEdge;
        height += _imageEditSizeStep) {
      final pixels = width * height;
      if (pixels < _imageEditMinPixels || pixels > _imageEditMaxPixels) {
        continue;
      }

      final ratio = math.max(width, height) / math.min(width, height);
      if (ratio > 3) continue;

      final relativeWidthError = (width - targetWidth).abs() / targetWidth;
      final relativeHeightError = (height - targetHeight).abs() / targetHeight;
      final aspectError = math.log((width / height) / targetRatio).abs();
      final areaError = (pixels - targetPixels).abs() / targetPixels;
      final score =
          relativeWidthError + relativeHeightError + aspectError * 2 + areaError * 0.05;

      final isBetterScore = score < bestScore - 0.000000001;
      final isBetterTie =
          (score - bestScore).abs() <= 0.000000001 && pixels > (best?.pixels ?? 0);
      if (isBetterScore || isBetterTie) {
        bestScore = score;
        best = _ImageEditSize(width, height);
      }
    }
  }

  return best ?? _ImageEditSize(1024, 1024);
}

Future<_Result> _runAppFlow({
  required String apiKey,
  required String model,
  required String prompt,
  required img.Image original,
  required bool sendFullRes,
  required Directory outDir,
}) async {
  final sent = sendFullRes ? original : _downscaled(original, _previewMaxDimension);
  final jpeg = img.encodeJpg(sent, quality: 90);
  final currentStateJson = EditorEditState.empty().toJsonString();
  final requestBody = {
    'model': model,
    'instructions': AiProvider.systemPrompt,
    'input': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': 'Return JSON only.\n\nCURRENT STATE:\n$currentStateJson'
                '\n\nUSER: $prompt',
          },
          {'type': 'input_text', 'text': 'TARGET IMAGE: current edited photo.'},
          {
            'type': 'input_image',
            'image_url': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
          },
        ],
      },
    ],
    'text': {
      'format': {'type': 'json_object'},
    },
  };

  await File('${outDir.path}/path_a_request_metadata.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'model': model,
      'sent_resolution': '${sent.width}x${sent.height}',
      'current_state_json': currentStateJson,
      'prompt': prompt,
      'note': 'The request image bytes are omitted from this metadata file.',
    }),
  );

  final sw = Stopwatch()..start();
  final response = await http.post(
    _responsesUrl,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(requestBody),
  );
  sw.stop();

  final responseFile = '${outDir.path}/path_a_response.json';
  await File(responseFile).writeAsString(_pretty(response.body));

  final sentRes = '${sent.width}x${sent.height}'
      '${sendFullRes ? " (original)" : " (preview)"}';
  final outFile = '${outDir.path}/path_a_app_flow.jpg';
  if (response.statusCode != 200) {
    return _errorResult(
      label: 'A) Moodit app flow',
      sentResolution: sentRes,
      latency: sw.elapsed,
      outputFile: outFile,
      responseFile: responseFile,
      response: response,
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final usage = _asStringMap(json['usage']);
  final outputText = _extractOutputText(json);

  String? note;
  if (outputText != null) {
    final parsed = parseEditsJson(outputText);
    if (parsed.edits != null) {
      final edited = applyEditsToImageSync(
        image: original,
        edits: parsed.edits!.edits,
        colorEdits: parsed.edits!.colorEdits,
        colorGradingEdits: parsed.edits!.colorGradingEdits,
      );
      await File(outFile).writeAsBytes(img.encodeJpg(edited, quality: 95));
      await File('${outDir.path}/path_a_edits.json').writeAsString(outputText);
      note = 'ops: ${parsed.edits!.edits.length} basic, '
          '${parsed.edits!.colorEdits.length} color, '
          '${parsed.edits!.colorGradingEdits.length} grading';
    } else {
      note = 'parse failed: ${parsed.error}';
    }
  } else {
    note = 'no output text';
  }

  return _resultFromUsage(
    label: 'A) Moodit app flow',
    sentResolution: sentRes,
    latency: sw.elapsed,
    outputFile: outFile,
    responseFile: responseFile,
    note: note,
    usage: usage,
  );
}

Future<_Result> _runImageEdit({
  required String apiKey,
  required String model,
  required String prompt,
  required String imagePath,
  required Uint8List imageBytes,
  required img.Image original,
  required String quality,
  required String size,
  required String outputFormat,
  required String outputExtension,
  required Directory outDir,
}) async {
  final multipartImage = _multipartImagePayload(
    imagePath: imagePath,
    imageBytes: imageBytes,
    decoded: original,
  );
  final request = http.MultipartRequest('POST', _imageEditsUrl)
    ..headers['Authorization'] = 'Bearer $apiKey'
    ..fields['model'] = model
    ..fields['prompt'] = prompt
    ..fields['quality'] = quality
    ..fields['size'] = size
    ..fields['output_format'] = outputFormat
    ..files.add(
      http.MultipartFile.fromBytes(
        'image[]',
        multipartImage.bytes,
        filename: multipartImage.filename,
        contentType: multipartImage.contentType,
      ),
    );

  await File('${outDir.path}/path_b_request_metadata.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'endpoint': '/v1/images/edits',
      'model': model,
      'sent_resolution': '${original.width}x${original.height}',
      'quality': quality,
      'size': size,
      'output_format': outputFormat,
      'prompt': prompt,
      'image_field': 'image[]',
      'multipart_filename': multipartImage.filename,
      'multipart_content_type': multipartImage.contentType.toString(),
      'multipart_note': multipartImage.note,
      'note': 'The multipart image bytes are omitted from this metadata file.',
    }),
  );

  final sw = Stopwatch()..start();
  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  sw.stop();

  final responseFile = '${outDir.path}/path_b_image_edits_response.json';
  await File(responseFile).writeAsString(_pretty(response.body));

  final sentRes = '${original.width}x${original.height} (original)';
  final outFile = '${outDir.path}/path_b_image_edit.$outputExtension';
  if (response.statusCode != 200) {
    return _errorResult(
      label: 'B) Image API edit',
      sentResolution: sentRes,
      latency: sw.elapsed,
      outputFile: outFile,
      responseFile: responseFile,
      response: response,
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final usage = _asStringMap(json['usage']);
  final imageBase64 = _extractImageApiBase64(json);
  String? note;
  if (imageBase64 != null) {
    await File(outFile).writeAsBytes(base64Decode(imageBase64));
  } else {
    note = 'no data[0].b64_json in response';
  }

  return _resultFromUsage(
    label: 'B) Image API edit',
    sentResolution: sentRes,
    latency: sw.elapsed,
    outputFile: outFile,
    responseFile: responseFile,
    note: note,
    usage: usage,
  );
}

class _MultipartImagePayload {
  final Uint8List bytes;
  final String filename;
  final MediaType contentType;
  final String note;

  _MultipartImagePayload({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.note,
  });
}

_MultipartImagePayload _multipartImagePayload({
  required String imagePath,
  required Uint8List imageBytes,
  required img.Image decoded,
}) {
  final filename = _basename(imagePath);
  final lower = filename.toLowerCase();

  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return _MultipartImagePayload(
      bytes: imageBytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
      note: 'Original file bytes sent as image/jpeg.',
    );
  }
  if (lower.endsWith('.png')) {
    return _MultipartImagePayload(
      bytes: imageBytes,
      filename: filename,
      contentType: MediaType('image', 'png'),
      note: 'Original file bytes sent as image/png.',
    );
  }
  if (lower.endsWith('.webp')) {
    return _MultipartImagePayload(
      bytes: imageBytes,
      filename: filename,
      contentType: MediaType('image', 'webp'),
      note: 'Original file bytes sent as image/webp.',
    );
  }

  return _MultipartImagePayload(
    bytes: Uint8List.fromList(img.encodePng(decoded)),
    filename: '${_stem(filename)}.png',
    contentType: MediaType('image', 'png'),
    note: 'Original extension was not supported by Image API; sent PNG bytes.',
  );
}

_Result _errorResult({
  required String label,
  required String sentResolution,
  required Duration latency,
  required String outputFile,
  required String responseFile,
  required http.Response response,
}) {
  Map<String, dynamic>? usage;
  try {
    usage = _asStringMap((jsonDecode(response.body) as Map)['usage']);
  } catch (_) {
    usage = null;
  }
  return _resultFromUsage(
    label: label,
    sentResolution: sentResolution,
    latency: latency,
    outputFile: outputFile,
    responseFile: responseFile,
    note: 'HTTP ${response.statusCode}: ${response.body}',
    usage: usage,
  );
}

_Result _skippedResult({
  required String label,
  required String sentResolution,
  required String note,
}) {
  return _Result(
    label: label,
    sentResolution: sentResolution,
    inputTokens: null,
    inputImageTokens: null,
    inputTextTokens: null,
    outputTokens: null,
    outputImageTokens: null,
    outputTextTokens: null,
    totalTokens: null,
    latency: Duration.zero,
    outputFile: '-',
    responseFile: '-',
    note: note,
    usageRaw: null,
  );
}

_Result _resultFromUsage({
  required String label,
  required String sentResolution,
  required Duration latency,
  required String outputFile,
  required String responseFile,
  required String? note,
  required Map<String, dynamic>? usage,
}) {
  final inputDetails = _asStringMap(usage?['input_tokens_details']);
  final outputDetails = _asStringMap(usage?['output_tokens_details']);
  return _Result(
    label: label,
    sentResolution: sentResolution,
    inputTokens: _asInt(usage?['input_tokens']),
    inputImageTokens: _asInt(inputDetails?['image_tokens']),
    inputTextTokens: _asInt(inputDetails?['text_tokens']),
    outputTokens: _asInt(usage?['output_tokens']),
    outputImageTokens: _asInt(outputDetails?['image_tokens']),
    outputTextTokens: _asInt(outputDetails?['text_tokens']),
    totalTokens: _asInt(usage?['total_tokens']),
    latency: latency,
    outputFile: outputFile,
    responseFile: responseFile,
    note: note,
    usageRaw: usage,
  );
}

String _buildReport(
  _Options options,
  _ResolvedImageEditOptions imageEditOptions,
  _Result a,
  _Result b,
) {
  String row(_Result r) {
    return [
      r.label.padRight(22),
      'in=${r.inputTokens ?? "-"}'.padRight(12),
      'img_in=${r.inputImageTokens ?? "-"}'.padRight(14),
      'txt_in=${r.inputTextTokens ?? "-"}'.padRight(14),
      'out=${r.outputTokens ?? "-"}'.padRight(12),
      'img_out=${r.outputImageTokens ?? "-"}'.padRight(15),
      'txt_out=${r.outputTextTokens ?? "-"}'.padRight(15),
      'total=${r.totalTokens ?? "-"}'.padRight(14),
      '${r.latency.inMilliseconds}ms',
    ].join(' ');
  }

  return [
    '=== Moodit AI edit comparison ===',
    'image: ${options.imagePath}',
    'prompt: ${options.prompt}',
    'path A model: ${options.paramModel}',
    'path A sent: ${options.aFullRes ? "original" : "preview 1080px"}',
    'path B endpoint: /v1/images/edits',
    'path B model: ${options.imageModel}',
    'path B options: quality=${options.imageQuality}, size=${imageEditOptions.size}, '
        'format=${imageEditOptions.outputFormat}',
    if (imageEditOptions.note != null) 'path B note: ${imageEditOptions.note}',
    '',
    row(a),
    '    sent: ${a.sentResolution}',
    if (a.note != null) '    ${a.note}',
    '    response: ${a.responseFile}',
    '    output: ${a.outputFile}',
    '    usage: ${jsonEncode(a.usageRaw)}',
    row(b),
    '    sent: ${b.sentResolution}',
    if (b.note != null) '    ${b.note}',
    '    response: ${b.responseFile}',
    '    output: ${b.outputFile}',
    '    usage: ${jsonEncode(b.usageRaw)}',
    '',
    'Interpretation note:',
    'Path A input tokens include the vision input plus text prompt/system context.',
    'Path B usage, when returned by the Image API, can split input image/text tokens',
    'and output image tokens. Keep the full JSON responses for the final analysis.',
  ].join('\n');
}

String? _extractImageApiBase64(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List || data.isEmpty) return null;
  final first = data.first;
  if (first is! Map) return null;
  final b64 = first['b64_json'];
  return b64 is String && b64.isNotEmpty ? b64 : null;
}

String? _extractOutputText(Map<String, dynamic> json) {
  final direct = json['output_text'];
  if (direct is String) return direct;
  final output = json['output'];
  if (output is! List) return null;
  final chunks = <String>[];
  for (final item in output) {
    if (item is! Map) continue;
    final content = item['content'];
    if (content is! List) continue;
    for (final contentItem in content) {
      if (contentItem is Map &&
          contentItem['text'] is String &&
          (contentItem['text'] as String).isNotEmpty) {
        chunks.add(contentItem['text'] as String);
      }
    }
  }
  return chunks.isEmpty ? null : chunks.join();
}

String _pretty(String body) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
  } catch (_) {
    return body;
  }
}

img.Image _downscaled(img.Image src, int maxDim) {
  final longest = src.width > src.height ? src.width : src.height;
  if (longest <= maxDim) return src;
  return src.width >= src.height
      ? img.copyResize(src, width: maxDim)
      : img.copyResize(src, height: maxDim);
}

String? _readApiKey() {
  final env = Platform.environment['OPENAI_API_KEY'];
  if (env != null && env.trim().isNotEmpty) return env.trim();

  final file = File('.env');
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('OPENAI_API_KEY=')) continue;
    final value =
        trimmed.substring('OPENAI_API_KEY='.length).trim().replaceAll('"', '');
    if (value.isNotEmpty) return value;
  }
  return null;
}

Map<String, dynamic>? _asStringMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String _defaultOutDir(String imagePath) {
  final stem = _stem(_basename(imagePath));
  final clean = _sanitize(stem).toLowerCase();
  final prefix = clean.length <= 5 ? clean : clean.substring(0, 5);
  return 'tool/results_${prefix.isEmpty ? "image" : prefix}';
}

String _formatFromPath(String path) {
  final lower = _basename(path).toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
  if (lower.endsWith('.webp')) return 'webp';
  return 'png';
}

String _normalizeOutputFormat(String value) {
  final lower = value.toLowerCase();
  if (lower == 'jpg') return 'jpeg';
  return lower;
}

String _extensionFromPath(String path, {required String fallbackFormat}) {
  final lower = _basename(path).toLowerCase();
  if (lower.endsWith('.jpg')) return 'jpg';
  if (lower.endsWith('.jpeg')) return 'jpeg';
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.webp')) return 'webp';
  return _extensionForFormat(fallbackFormat);
}

String _extensionForFormat(String format) {
  if (format == 'jpeg') return 'jpg';
  return format;
}

String _basename(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isEmpty ? path : parts.last;
}

String _stem(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot <= 0) return filename;
  return filename.substring(0, dot);
}

String _sanitize(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

String _readFlagValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag');
    exit(64);
  }
  return args[index];
}

const String _usage = '''
Usage:
  dart run tool/ai_compare.dart <image> "<prompt>" [options]

Options:
  --only-a                 Run only Path A / Moodit app flow.
  --only-b                 Run only Path B / Image API edits.
  --a-full-res              Path A sends the original image instead of the 1080px preview.
                            Use this for the single high-resolution Prague case.
  --a-preview               Path A sends the 1080px preview. This is the default.
  --param-model <model>     Model for Path A / Responses JSON. Default: $_defaultParamModel
  --image-model <model>     Model for Path B / Image API edits. Default: $_defaultImageModel
  --quality <value>         Image API quality. Default: $_defaultImageQuality
  --size <value>            Image API size. Default: max-valid (largest valid size
                            close to the input aspect/resolution). Use same for exact input size.
  --output-format <value>   png, jpeg, webp, or same. Default: same
  --out-dir <dir>           Override output dir. Default: tool/results_<first_5_letters>

Examples:
  dart run tool/ai_compare.dart tool/praga.jpg "make it black and white" --a-full-res
  dart run tool/ai_compare.dart tool/iasi.jpg "make it warmer and cinematic"
''';
