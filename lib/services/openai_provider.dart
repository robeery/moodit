import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/ai_provider.dart';
import '../model/ai_exception.dart';
import '../model/chat_message.dart';

typedef OpenAiHttpPost = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
});

class OpenAiProvider implements AiProvider {
  static final Uri _responsesUrl = Uri.parse('https://api.openai.com/v1/responses');

  final String? _apiKeyOverride;
  final OpenAiHttpPost _post;

  OpenAiProvider({
    String? apiKey,
    OpenAiHttpPost? post,
  })  : _apiKeyOverride = apiKey,
        _post = post ?? http.post;

  String get _apiKey => _apiKeyOverride ?? '';

  @override
  String get name => 'OpenAI';

  @override
  List<String> get models => const [
        'gpt-5.5',
        'gpt-5.4',
        'gpt-5.4-mini',
      ];

  @override
  String get defaultModel => 'gpt-5.4-mini';

  @override
  Future<String> sendPrompt(
    String userMessage, {
    Uint8List? imageBytes,
    String? model,
    List<ChatMessage> history = const [],
    String? currentStateJson,
  }) async {
    final selectedModel = model ?? defaultModel;

    if (_apiKey.isEmpty || _apiKey == 'your_key_here') {
      throw const AiException(
        type: AiErrorType.authFailed,
        message: 'API key not configured. Set your OpenAI API key.',
      );
    }

    final body = jsonEncode({
      'model': selectedModel,
      'instructions': AiProvider.systemPrompt,
      'input': _buildInputMessages(
        userMessage,
        imageBytes: imageBytes,
        history: history,
        currentStateJson: currentStateJson,
      ),
      'text': {
        'format': {'type': 'json_object'},
      },
    });

    final http.Response response;
    try {
      response = await _post(
        _responsesUrl,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
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
      final outputText = _extractOutputText(json);
      if (outputText == null || outputText.trim().isEmpty) {
        throw const AiException(
          type: AiErrorType.badResponse,
          message: 'No response from AI.',
        );
      }
      return outputText;
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException(
        type: AiErrorType.badResponse,
        message: 'AI returned an unexpected response format.',
      );
    }
  }

  List<Map<String, dynamic>> _buildInputMessages(
    String userMessage, {
    required Uint8List? imageBytes,
    required List<ChatMessage> history,
    required String? currentStateJson,
  }) {
    final input = <Map<String, dynamic>>[];

    for (final message in history) {
      if (message.isError) continue;
      input.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    final content = <Map<String, dynamic>>[];
    final messageText = currentStateJson != null
        ? 'Return JSON only.\n\nCURRENT STATE:\n$currentStateJson\n\nUSER: $userMessage'
        : 'Return JSON only.\n\nUSER: $userMessage';
    content.add({'type': 'input_text', 'text': messageText});

    if (imageBytes != null) {
      content.add({
        'type': 'input_image',
        'image_url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
      });
    }

    input.add({'role': 'user', 'content': content});
    return input;
  }

  String? _extractOutputText(Map<String, dynamic> responseJson) {
    final outputText = responseJson['output_text'];
    if (outputText is String) return outputText;

    final output = responseJson['output'];
    if (output is! List) return null;

    final chunks = <String>[];
    for (final item in output) {
      if (item is! Map) continue;
      final content = item['content'];
      if (content is! List) continue;

      for (final contentItem in content) {
        if (contentItem is! Map) continue;
        final text = contentItem['text'];
        if (text is String && text.isNotEmpty) {
          chunks.add(text);
        }
      }
    }

    if (chunks.isEmpty) return null;
    return chunks.join();
  }
}
