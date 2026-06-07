import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:licenta/model/ai_exception.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/services/claude_provider.dart';

void main() {
  test('throws auth error when API key is missing', () async {
    final provider = ClaudeProvider();

    expect(
      () => provider.sendPrompt('Make it warmer'),
      throwsA(
        isA<AiException>()
            .having((e) => e.type, 'type', AiErrorType.authFailed)
            .having((e) => e.message, 'message', contains('Anthropic')),
      ),
    );
  });

  test('sends history, images, state, and structured output request', () async {
    Uri? capturedUrl;
    Map<String, String>? capturedHeaders;
    Object? capturedBody;

    final provider = ClaudeProvider(
      apiKey: 'test-key',
      post: (url, {headers, body, encoding}) async {
        capturedUrl = url;
        capturedHeaders = headers;
        capturedBody = body;
        return http.Response(
          jsonEncode({
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({
                  'message': 'Done',
                  'edits': [],
                  'colorEdits': [],
                  'colorGradingEdits': [],
                }),
              },
            ],
          }),
          200,
        );
      },
    );

    final reply = await provider.sendPrompt(
      'Match the reference mood',
      imageBytes: Uint8List.fromList([1, 2, 3]),
      referenceImageBytes: Uint8List.fromList([4, 5, 6]),
      model: 'claude-sonnet-4-6',
      history: [
        ChatMessage(text: 'Previous request', type: MessageType.user),
        ChatMessage(text: 'Previous answer', type: MessageType.ai),
        ChatMessage(text: 'Ignored error', type: MessageType.error),
      ],
      currentStateJson: '{"edits":[]}',
    );

    expect(
      jsonDecode(reply),
      {
        'message': 'Done',
        'edits': [],
        'colorEdits': [],
        'colorGradingEdits': [],
      },
    );
    expect(capturedUrl, Uri.parse('https://api.anthropic.com/v1/messages'));
    expect(capturedHeaders?['x-api-key'], 'test-key');
    expect(capturedHeaders?['anthropic-version'], '2023-06-01');
    expect(capturedHeaders?['content-type'], 'application/json');

    final body = jsonDecode(capturedBody as String) as Map<String, dynamic>;
    expect(body['model'], 'claude-sonnet-4-6');
    expect(body['max_tokens'], 1024);
    expect(body['system'], contains('photo editing assistant'));

    final outputFormat =
        body['output_config']['format'] as Map<String, dynamic>;
    expect(outputFormat['type'], 'json_schema');
    expect(outputFormat['schema']['required'], ['message']);
    expect(outputFormat['schema']['properties'], contains('edits'));

    final messages = body['messages'] as List<dynamic>;
    expect(messages, hasLength(3));
    expect(messages[0], {
      'role': 'user',
      'content': 'Previous request',
    });
    expect(messages[1], {
      'role': 'assistant',
      'content': 'Previous answer',
    });

    final currentMessage = messages[2] as Map<String, dynamic>;
    expect(currentMessage['role'], 'user');
    final content = currentMessage['content'] as List<dynamic>;
    expect(content[0], {
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': 'image/jpeg',
        'data': 'AQID',
      },
    });
    expect(content[1], {
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': 'image/jpeg',
        'data': 'BAUG',
      },
    });
    expect(content[2]['type'], 'text');
    expect(content[2]['text'], contains('first image is the TARGET IMAGE'));
    expect(content[2]['text'], contains('second image is the REFERENCE IMAGE'));
    expect(content[2]['text'], contains('CURRENT STATE'));
    expect(content[2]['text'], contains('"edits":[]'));
    expect(content[2]['text'], contains('USER: Match the reference mood'));
  });

  test('rejects a successful response without text content', () async {
    final provider = ClaudeProvider(
      apiKey: 'test-key',
      post: (url, {headers, body, encoding}) async {
        return http.Response(jsonEncode({'content': []}), 200);
      },
    );

    expect(
      () => provider.sendPrompt('Make it softer'),
      throwsA(
        isA<AiException>().having(
          (e) => e.type,
          'type',
          AiErrorType.badResponse,
        ),
      ),
    );
  });
}
