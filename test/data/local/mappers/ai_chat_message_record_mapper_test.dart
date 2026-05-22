import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/data/local/app_database.dart';
import 'package:licenta/data/local/mappers/ai_chat_message_record_mapper.dart';
import 'package:licenta/model/chat_message.dart';

void main() {
  test('chat message maps to Drift companion', () {
    final createdAt = DateTime.utc(2026, 5, 19, 11);
    final message = ChatMessage(
      text: 'Make it warmer',
      type: MessageType.user,
      timestamp: createdAt,
    );

    final companion = message.toProjectRecordCompanion(
      projectId: 4,
      sortOrder: 2,
    );

    expect(companion.projectId.value, 4);
    expect(companion.versionId.value, isNull);
    expect(companion.type.value, MessageType.user.name);
    expect(companion.messageText.value, 'Make it warmer');
    expect(companion.createdAt.value, createdAt);
    expect(companion.sortOrder.value, 2);
  });

  test('chat message maps to version Drift companion', () {
    final createdAt = DateTime.utc(2026, 5, 19, 11);
    final message = ChatMessage(
      text: 'Make it softer',
      type: MessageType.user,
      timestamp: createdAt,
    );

    final companion = message.toVersionRecordCompanion(
      projectId: 4,
      versionId: 'version-1',
      sortOrder: 3,
    );

    expect(companion.projectId.value, 4);
    expect(companion.versionId.value, 'version-1');
    expect(companion.type.value, MessageType.user.name);
    expect(companion.messageText.value, 'Make it softer');
    expect(companion.createdAt.value, createdAt);
    expect(companion.sortOrder.value, 3);
  });

  test('chat Drift record maps to app model', () {
    final createdAt = DateTime.utc(2026, 5, 19, 11);
    final record = AiChatMessageRecord(
      id: 1,
      projectId: 4,
      versionId: null,
      type: MessageType.ai.name,
      messageText: 'Added warmth.',
      createdAt: createdAt,
      sortOrder: 2,
    );

    final message = record.toModel();

    expect(message.text, 'Added warmth.');
    expect(message.type, MessageType.ai);
    expect(message.timestamp, createdAt);
  });

  test('unknown message type maps to ai', () {
    final createdAt = DateTime.utc(2026, 5, 19, 11);
    final record = AiChatMessageRecord(
      id: 1,
      projectId: 4,
      versionId: null,
      type: 'old-or-invalid',
      messageText: 'Fallback',
      createdAt: createdAt,
      sortOrder: 2,
    );

    expect(record.toModel().type, MessageType.ai);
  });
}
