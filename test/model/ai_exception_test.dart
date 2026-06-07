import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/ai_exception.dart';

void main() {
  test('status mapper preserves provider error messages', () {
    final exception = AiException.fromStatusCode(
      400,
      '{"error":{"message":"Unsupported parameter: text.format"}}',
    );

    expect(exception.type, AiErrorType.invalidRequest);
    expect(exception.message, contains('Unsupported parameter: text.format'));
    expect(exception.statusCode, 400);
  });

  test('status mapper falls back to generic messages for malformed bodies', () {
    final exception = AiException.fromStatusCode(400, 'not json');

    expect(exception.type, AiErrorType.invalidRequest);
    expect(exception.message, contains('Invalid request'));
    expect(exception.statusCode, 400);
  });

  test('status mapper treats Anthropic overloads as retryable', () {
    final exception = AiException.fromStatusCode(
      529,
      '{"error":{"message":"Overloaded"}}',
    );

    expect(exception.type, AiErrorType.serviceUnavailable);
    expect(exception.message, contains('Overloaded'));
    expect(exception.retryable, isTrue);
    expect(exception.statusCode, 529);
  });

  test('status mapper explains oversized multimodal requests', () {
    final exception = AiException.fromStatusCode(413, 'not json');

    expect(exception.type, AiErrorType.invalidRequest);
    expect(exception.message, contains('too large'));
    expect(exception.retryable, isFalse);
    expect(exception.statusCode, 413);
  });
}
