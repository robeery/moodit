import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/domain/parse_edits_json.dart';

void main() {
  test('accepts a message with empty edit arrays', () {
    final result = parseEditsJson(
      '{"message":"That request does not describe an image edit.",'
      '"edits":[],"colorEdits":[],"colorGradingEdits":[]}',
    );

    expect(result.error, isNull);
    expect(result.edits?.message,
        'That request does not describe an image edit.');
    expect(result.edits?.hasOperations, isFalse);
  });

  test('accepts a message with omitted edit arrays', () {
    final result = parseEditsJson(
      '{"message":"Please attach the reference image first."}',
    );

    expect(result.error, isNull);
    expect(result.edits?.hasOperations, isFalse);
  });

  test('requires a non-empty message', () {
    final missing = parseEditsJson(
      '{"edits":[{"type":"brightness","value":10}]}',
    );
    final empty = parseEditsJson(
      '{"message":"   ","edits":[{"type":"brightness","value":10}]}',
    );

    expect(missing.error, '"message" must be a string');
    expect(empty.error, '"message" must not be empty');
  });

  test('rejects incorrectly typed edit collections without throwing', () {
    final basic = parseEditsJson('{"message":"No.","edits":"wrong"}');
    final selective =
        parseEditsJson('{"message":"No.","colorEdits":42}');
    final grading = parseEditsJson(
      '{"message":"No.","colorGradingEdits":{}}',
    );

    expect(basic.error, '"edits" must be an array');
    expect(selective.error, '"colorEdits" must be an array');
    expect(grading.error, '"colorGradingEdits" must be an array');
  });

  test('continues to parse valid image operations', () {
    final result = parseEditsJson(
      '{"message":"Brightened the image.",'
      '"edits":[{"type":"brightness","value":15}]}',
    );

    expect(result.error, isNull);
    expect(result.edits?.hasOperations, isTrue);
    expect(result.edits?.edits.single.value, 15);
  });
}
