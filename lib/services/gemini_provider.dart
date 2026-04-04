import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../domain/ai_provider.dart';
import '../model/ai_exception.dart';
import '../model/chat_message.dart';

class GeminiProvider implements AiProvider {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final String? _apiKeyOverride;

  GeminiProvider({String? apiKey}) : _apiKeyOverride = apiKey;

  String get _apiKey => _apiKeyOverride ?? '';

  @override
  String get name => 'Gemini';

  @override
  List<String> get models => const [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  @override
  String get defaultModel => 'gemini-2.5-flash-lite';

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
        message: 'API key not configured. Set your Gemini API key.',
      );
    }

    final url = Uri.parse('$_baseUrl/$selectedModel:generateContent?key=$_apiKey');

    // Build conversation history (text only, no images in past turns)
    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      if (msg.isError) continue;
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }

    // Build current message: image + current state + user text
    final currentParts = <Map<String, dynamic>>[];
    if (imageBytes != null) {
      currentParts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }
    final messageText = currentStateJson != null
        ? 'CURRENT STATE:\n$currentStateJson\n\nUSER: $userMessage'
        : userMessage;
    currentParts.add({'text': messageText});
    contents.add({'role': 'user', 'parts': currentParts});

    final body = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': AiProvider.systemPrompt},
        ],
      },
      'generationConfig': {
        'responseMimeType': 'application/json',
      },
    });

    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
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
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiException(
          type: AiErrorType.badResponse,
          message: 'No response from AI - may have been blocked by safety filters.',
        );
      }
      final text =
          candidates[0]['content']['parts'][0]['text'] as String;
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
}
