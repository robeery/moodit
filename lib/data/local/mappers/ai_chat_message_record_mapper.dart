import 'package:drift/drift.dart';

import '../../../model/chat_message.dart';
import '../app_database.dart';

extension AiChatMessageRecordMapper on AiChatMessageRecord {
  ChatMessage toModel() {
    return ChatMessage(
      text: messageText,
      type: _messageTypeFromStorage(type),
      timestamp: createdAt,
    );
  }
}

extension AiChatMessageMapper on ChatMessage {
  AiChatMessageRecordsCompanion toProjectRecordCompanion({
    required int projectId,
    required int sortOrder,
  }) {
    return AiChatMessageRecordsCompanion.insert(
      projectId: projectId,
      versionId: const Value(null),
      type: type.name,
      messageText: text,
      createdAt: timestamp,
      sortOrder: sortOrder,
    );
  }

  AiChatMessageRecordsCompanion toVersionRecordCompanion({
    required int projectId,
    required String versionId,
    required int sortOrder,
  }) {
    return AiChatMessageRecordsCompanion.insert(
      projectId: projectId,
      versionId: Value(versionId),
      type: type.name,
      messageText: text,
      createdAt: timestamp,
      sortOrder: sortOrder,
    );
  }
}

MessageType _messageTypeFromStorage(String value) {
  for (final type in MessageType.values) {
    if (type.name == value) return type;
  }
  return MessageType.ai;
}
