part of '../app_database.dart';

@DriftAccessor(tables: [AiChatMessageRecords])
class AiChatMessagesDao extends DatabaseAccessor<AppDatabase>
    with _$AiChatMessagesDaoMixin {
  AiChatMessagesDao(super.db);

  Future<List<AiChatMessageRecord>> loadForProject(int projectId) {
    final query = select(aiChatMessageRecords)
      ..where((table) => table.projectId.equals(projectId))
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
    final query = select(aiChatMessageRecords)
      ..where((table) => table.projectId.equals(projectId))
      ..orderBy([
        (table) => OrderingTerm.desc(table.sortOrder),
        (table) => OrderingTerm.desc(table.createdAt),
        (table) => OrderingTerm.desc(table.id),
      ])
      ..limit(1);

    final latest = await query.getSingleOrNull();
    return (latest?.sortOrder ?? 0) + 1;
  }

  Future<int> clearForProject(int projectId) {
    final query = delete(aiChatMessageRecords)
      ..where((table) => table.projectId.equals(projectId));

    return query.go();
  }
}
