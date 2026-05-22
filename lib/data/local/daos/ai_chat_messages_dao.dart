part of '../app_database.dart';

@DriftAccessor(tables: [AiChatMessageRecords])
class AiChatMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$AiChatMessagesDaoMixin {
  AiChatMessagesDao(super.db);

  Future<List<AiChatMessageRecord>> loadForProject(int projectId) {
    final query = select(aiChatMessageRecords)
      ..where((table) => _projectScope(table, projectId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
        (table) => OrderingTerm.asc(table.id),
      ]);

    return query.get();
  }

  Future<List<AiChatMessageRecord>> loadForVersion({
    required int projectId,
    required String versionId,
  }) {
    final query = select(aiChatMessageRecords)
      ..where((table) => _versionScope(table, projectId, versionId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.createdAt),
        (table) => OrderingTerm.asc(table.id),
      ]);

    return query.get();
  }

  Future<void> insertMessage(AiChatMessageRecordsCompanion message) async {
    await into(aiChatMessageRecords).insert(message);
  }

  Future<int> nextSortOrderForProject(int projectId) async {
    return _nextSortOrder((table) => _projectScope(table, projectId));
  }

  Future<int> nextSortOrderForVersion({
    required int projectId,
    required String versionId,
  }) async {
    return _nextSortOrder(
      (table) => _versionScope(table, projectId, versionId),
    );
  }

  Future<int> clearForProject(int projectId) {
    final query = delete(aiChatMessageRecords)
      ..where((table) => table.projectId.equals(projectId));

    return query.go();
  }

  Future<int> clearForVersion({
    required int projectId,
    required String versionId,
  }) {
    final query = delete(aiChatMessageRecords)
      ..where((table) => _versionScope(table, projectId, versionId));

    return query.go();
  }

  Future<int> moveProjectMessagesToVersion({
    required int projectId,
    required String versionId,
  }) {
    final query = update(aiChatMessageRecords)
      ..where((table) => _projectScope(table, projectId));

    return query.write(AiChatMessageRecordsCompanion(
      versionId: Value(versionId),
    ));
  }

  Future<void> cloneVersionMessages({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {
    final messages = await loadForVersion(
      projectId: projectId,
      versionId: sourceVersionId,
    );
    for (final message in messages) {
      await insertMessage(AiChatMessageRecordsCompanion.insert(
        projectId: projectId,
        versionId: Value(targetVersionId),
        type: message.type,
        messageText: message.messageText,
        createdAt: message.createdAt,
        sortOrder: message.sortOrder,
      ));
    }
  }

  Future<int> _nextSortOrder(
    Expression<bool> Function(AiChatMessageRecords table) where,
  ) async {
    final query = select(aiChatMessageRecords)
      ..where(where)
      ..orderBy([
        (table) => OrderingTerm.desc(table.sortOrder),
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.desc(table.id),
      ])
      ..limit(1);

    final latest = await query.getSingleOrNull();
    return (latest?.sortOrder ?? 0) + 1;
  }

  Expression<bool> _projectScope(
    AiChatMessageRecords table,
    int projectId,
  ) {
    return table.projectId.equals(projectId) & table.versionId.isNull();
  }

  Expression<bool> _versionScope(
    AiChatMessageRecords table,
    int projectId,
    String versionId,
  ) {
    return table.projectId.equals(projectId) & table.versionId.equals(versionId);
  }
}
