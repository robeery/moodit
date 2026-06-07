import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/ai_provider.dart';
import '../model/ai_exception.dart';
import '../model/chat_message.dart';

typedef ClaudeHttpPost = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
});

class ClaudeProvider implements AiProvider {
  static final Uri _messagesUrl =
      Uri.parse('https://api.anthropic.com/v1/messages');
  static const String _apiVersion = '2023-06-01';
  static const int _maxTokens = 1024;

  final String? _apiKeyOverride;
  final ClaudeHttpPost _post;

  ClaudeProvider({
    String? apiKey,
    ClaudeHttpPost? post,
  })  : _apiKeyOverride = apiKey,
        _post = post ?? http.post;

  String get _apiKey => _apiKeyOverride ?? '';

  @override
  String get name => 'Claude';

  @override
  List<String> get models => const [
        'claude-haiku-4-5',
        'claude-sonnet-4-6',
        'claude-opus-4-8',
        'claude-fable-5',
      ];

  @override
  String get defaultModel => 'claude-haiku-4-5';

  @override
  Future<String> sendPrompt(
    String userMessage, {
    Uint8List? imageBytes,
    Uint8List? referenceImageBytes,
    String? model,
    List<ChatMessage> history = const [],
    String? currentStateJson,
  }) async {
    final selectedModel = model ?? defaultModel;

    if (_apiKey.isEmpty || _apiKey == 'your_key_here') {
      throw const AiException(
        type: AiErrorType.authFailed,
        message: 'API key not configured. Set your Anthropic API key.',
      );
    }

    final body = jsonEncode({
      'model': selectedModel,
      'max_tokens': _maxTokens,
      'system': AiProvider.systemPrompt,
      'messages': _buildMessages(
        userMessage,
        imageBytes: imageBytes,
        referenceImageBytes: referenceImageBytes,
        history: history,
        currentStateJson: currentStateJson,
      ),
      'output_config': {
        'format': {
          'type': 'json_schema',
          'schema': _responseSchema,
        },
      },
    });

    final http.Response response;
    try {
      response = await _post(
        _messagesUrl,
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
          'content-type': 'application/json',
        },
        body: body,
      );
    } on HandshakeException {
      throw const AiException(
        type: AiErrorType.unknown,
        message: 'Secure connection failed. Check your network.',
        retryable: true,
      );
    } on SocketException {
      throw const AiException(
        type: AiErrorType.unknown,
        message: 'Connection failed. Check your internet.',
      );
    } on http.ClientException {
      throw const AiException(
        type: AiErrorType.unknown,
        message: 'Connection interrupted. Please try again.',
        retryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw AiException.fromStatusCode(response.statusCode, response.body);
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = _extractText(json);
      if (text == null || text.trim().isEmpty) {
        throw const AiException(
          type: AiErrorType.badResponse,
          message: 'No response from AI.',
        );
      }
      return text;
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException(
        type: AiErrorType.badResponse,
        message: 'AI returned an unexpected response format.',
      );
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String userMessage, {
    required Uint8List? imageBytes,
    required Uint8List? referenceImageBytes,
    required List<ChatMessage> history,
    required String? currentStateJson,
  }) {
    final messages = <Map<String, dynamic>>[];

    for (final message in history) {
      if (message.isError) continue;
      messages.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    final content = <Map<String, dynamic>>[];
    if (imageBytes != null) {
      content.add(_imageBlock(imageBytes));
    }
    if (referenceImageBytes != null) {
      content.add(_imageBlock(referenceImageBytes));
    }

    final imageContext = switch ((imageBytes, referenceImageBytes)) {
      (null, null) => '',
      (_, null) => 'The first image is the TARGET IMAGE.\n\n',
      (null, _) => 'The first image is the REFERENCE IMAGE.\n\n',
      (_, _) =>
        'The first image is the TARGET IMAGE. '
            'The second image is the REFERENCE IMAGE.\n\n',
    };
    final stateContext = currentStateJson == null
        ? ''
        : 'CURRENT STATE:\n$currentStateJson\n\n';
    content.add({
      'type': 'text',
      'text': '$imageContext${stateContext}USER: $userMessage',
    });

    messages.add({'role': 'user', 'content': content});
    return messages;
  }

  Map<String, dynamic> _imageBlock(Uint8List bytes) {
    return {
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': 'image/jpeg',
        'data': base64Encode(bytes),
      },
    };
  }

  String? _extractText(Map<String, dynamic> responseJson) {
    final content = responseJson['content'];
    if (content is! List) return null;

    final chunks = <String>[];
    for (final block in content) {
      if (block is! Map || block['type'] != 'text') continue;
      final text = block['text'];
      if (text is String && text.isNotEmpty) {
        chunks.add(text);
      }
    }

    if (chunks.isEmpty) return null;
    return chunks.join();
  }

  static const Map<String, dynamic> _responseSchema = {
    'type': 'object',
    'properties': {
      'message': {'type': 'string'},
      'edits': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': [
                'exposure',
                'brightness',
                'highlights',
                'shadows',
                'contrast',
                'warmth',
                'tint',
                'saturation',
                'vibrance',
                'vignette',
                'sharpness',
                'definition',
                'blackpoint',
                'blur',
                'grain',
                'fade',
              ],
            },
            'value': {'type': 'number'},
          },
          'required': ['type', 'value'],
          'additionalProperties': false,
        },
      },
      'colorEdits': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'range': {
              'type': 'string',
              'enum': [
                'red',
                'orange',
                'yellow',
                'green',
                'cyan',
                'blue',
                'purple',
                'magenta',
              ],
            },
            'hue': {'type': 'number'},
            'saturation': {'type': 'number'},
            'luminance': {'type': 'number'},
          },
          'required': ['range', 'hue', 'saturation', 'luminance'],
          'additionalProperties': false,
        },
      },
      'colorGradingEdits': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'zone': {
              'type': 'string',
              'enum': ['shadows', 'midtones', 'highlights', 'global'],
            },
            'hue': {'type': 'number'},
            'strength': {'type': 'number'},
            'luminance': {'type': 'number'},
          },
          'required': ['zone', 'hue', 'strength', 'luminance'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['message'],
    'additionalProperties': false,
  };
}
