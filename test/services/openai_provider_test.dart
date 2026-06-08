import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:licenta/model/ai_exception.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/services/openai_provider.dart';

void main() {
  test('throws auth error when API key is missing', () async {
    final provider = OpenAiProvider();

    expect(
      () => provider.sendPrompt('Make it warmer'),
      throwsA(
        isA<AiException>()
            .having((e) => e.type, 'type', AiErrorType.authFailed)
            .having((e) => e.message, 'message', contains('OpenAI')),
      ),
    );
  });

  test('sends current state, image, history, and JSON mode request', () async {
    Uri? capturedUrl;
    Map<String, String>? capturedHeaders;
    Object? capturedBody;

    final provider = OpenAiProvider(
      apiKey: 'test-key',
      post: (url, {headers, body, encoding}) async {
        capturedUrl = url;
        capturedHeaders = headers;
        capturedBody = body;
        return http.Response(
          jsonEncode({'output_text': '{"message":"Done"}'}),
          200,
        );
      },
    );

    final reply = await provider.sendPrompt(
      'Make it softer',
      imageBytes: Uint8List.fromList([1, 2, 3]),
      referenceImageBytes: Uint8List.fromList([4, 5, 6]),
      model: 'gpt-5.4-mini',
      history: [
        ChatMessage(text: 'Previous request', type: MessageType.user),
        ChatMessage(text: 'Previous answer', type: MessageType.ai),
        ChatMessage(text: 'Ignored error', type: MessageType.error),
      ],
      currentStateJson: '{"edits":[]}',
    );

    expect(reply, '{"message":"Done"}');
    expect(capturedUrl, Uri.parse('https://api.openai.com/v1/responses'));
    expect(capturedHeaders?['Authorization'], 'Bearer test-key');
    expect(capturedHeaders?['Content-Type'], 'application/json');

    final body = jsonDecode(capturedBody as String) as Map<String, dynamic>;
    expect(body['model'], 'gpt-5.4-mini');
    expect(body['instructions'], contains('photo editing assistant'));
    expect(body['instructions'], contains('Never invent edit operations'));
    expect(body['text'], {
      'format': {'type': 'json_object'},
    });

    final input = body['input'] as List<dynamic>;
    expect(input, hasLength(3));
    expect(input[0], {'role': 'user', 'content': 'Previous request'});
    expect(input[1], {'role': 'assistant', 'content': 'Previous answer'});

    final currentMessage = input[2] as Map<String, dynamic>;
    expect(currentMessage['role'], 'user');
    final content = currentMessage['content'] as List<dynamic>;
    expect(content[0]['type'], 'input_text');
    expect(content[0]['text'], contains('Return JSON only'));
    expect(content[0]['text'], contains('CURRENT STATE'));
    expect(content[0]['text'], contains('"edits":[]'));
    expect(content[0]['text'], contains('USER: Make it softer'));
    expect(content[1], {
      'type': 'input_text',
      'text': 'TARGET IMAGE: current edited photo.',
    });
    expect(content[2], {
      'type': 'input_image',
      'image_url': 'data:image/jpeg;base64,AQID',
    });
    expect(content[3], {
      'type': 'input_text',
      'text': 'REFERENCE IMAGE: visual style guidance only.',
    });
    expect(content[4], {
      'type': 'input_image',
      'image_url': 'data:image/jpeg;base64,BAUG',
    });
  });

  test('extracts nested output text from Responses API payload', () async {
    final provider = OpenAiProvider(
      apiKey: 'test-key',
      post: (url, {headers, body, encoding}) async {
        return http.Response(
          jsonEncode({
            'output': [
              {
                'type': 'message',
                'content': [
                  {'type': 'output_text', 'text': '{"message":"Nested"}'},
                ],
              },
            ],
          }),
          200,
        );
      },
    );

    final reply = await provider.sendPrompt('Make it softer');

    expect(reply, '{"message":"Nested"}');
  });
}
