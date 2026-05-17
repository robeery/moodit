import 'dart:convert';

import 'editor_history_entry.dart';

class EditorHistorySnapshot {
  const EditorHistorySnapshot({
    required this.undoEntries,
    required this.redoEntries,
  });

  factory EditorHistorySnapshot.empty() {
    return const EditorHistorySnapshot(
      undoEntries: [],
      redoEntries: [],
    );
  }

  factory EditorHistorySnapshot.fromJson(Map<String, dynamic> json) {
    return EditorHistorySnapshot(
      undoEntries: _decodeEntries(json['undo']),
      redoEntries: _decodeEntries(json['redo']),
    );
  }

  factory EditorHistorySnapshot.fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return EditorHistorySnapshot.empty();
      return EditorHistorySnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return EditorHistorySnapshot.empty();
    }
  }

  static const String emptyJson = '{"undo":[],"redo":[]}';

  final List<EditorHistoryEntry> undoEntries;
  final List<EditorHistoryEntry> redoEntries;

  Map<String, dynamic> toJson() {
    return {
      'undo': undoEntries.map((entry) => entry.toJson()).toList(),
      'redo': redoEntries.map((entry) => entry.toJson()).toList(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static List<EditorHistoryEntry> _decodeEntries(Object? value) {
    if (value is! List) return [];

    final entries = <EditorHistoryEntry>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        entries.add(EditorHistoryEntry.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Ignore malformed persisted history entries and keep the rest.
      }
    }
    return entries;
  }
}
