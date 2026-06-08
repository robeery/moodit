import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:licenta/model/ai_exception.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/services/gemini_provider.dart';

void main() {
  test('throws auth error when API key is missing', () async {
    final provider = GeminiProvider();

    expect(
      () => provider.sendPrompt('Make it warmer'),
      throwsA(
        isA<AiException>()
            .having((e) => e.type, 'type', AiErrorType.authFailed)
            .having((e) => e.message, 'message', contains('Gemini')),
      ),
    );
  });

  test('sends current state, target image, reference image, and history', () async {
    Uri? capturedUrl;
    Map<String, String>? capturedHeaders;
    Object? capturedBody;

    final provider = GeminiProvider(
      apiKey: 'test-key',
      post: (url, {headers, body, encoding}) async {
        capturedUrl = url;
        capturedHeaders = headers;
        capturedBody = body;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"message":"Done"}'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      },
    );

    final reply = await provider.sendPrompt(
      'Match this vibe',
      imageBytes: Uint8List.fromList([1, 2, 3]),
      referenceImageBytes: Uint8List.fromList([4, 5, 6]),
      model: 'gemini-2.5-flash-lite',
      history: [
        ChatMessage(text: 'Previous request', type: MessageType.user),
        ChatMessage(text: 'Previous answer', type: MessageType.ai),
        ChatMessage(text: 'Ignored error', type: MessageType.error),
      ],
      currentStateJson: '{"edits":[]}',
    );

    expect(reply, '{"message":"Done"}');
    expect(
      capturedUrl,
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.5-flash-lite:generateContent?key=test-key',
      ),
    );
    expect(capturedHeaders?['Content-Type'], 'application/json');

    final body = jsonDecode(capturedBody as String) as Map<String, dynamic>;
    expect(body['generationConfig'], {
      'responseMimeType': 'application/json',
    });
    expect(
      body['systemInstruction']['parts'][0]['text'],
      contains('Never invent edit operations'),
    );

    final contents = body['contents'] as List<dynamic>;
    expect(contents, hasLength(3));
    expect(contents[0]['role'], 'user');
    expect(contents[0]['parts'][0]['text'], 'Previous request');
    expect(contents[1]['role'], 'model');
    expect(contents[1]['parts'][0]['text'], 'Previous answer');

    final currentParts = contents[2]['parts'] as List<dynamic>;
    expect(currentParts[0]['text'], 'TARGET IMAGE: current edited photo.');
    expect(currentParts[1]['inline_data'], {
      'mime_type': 'image/jpeg',
      'data': 'AQID',
    });
    expect(
      currentParts[2]['text'],
      'REFERENCE IMAGE: visual style guidance only.',
    );
    expect(currentParts[3]['inline_data'], {
      'mime_type': 'image/jpeg',
      'data': 'BAUG',
    });
    expect(currentParts[4]['text'], contains('CURRENT STATE'));
    expect(currentParts[4]['text'], contains('"edits":[]'));
    expect(currentParts[4]['text'], contains('USER: Match this vibe'));
  });
}
