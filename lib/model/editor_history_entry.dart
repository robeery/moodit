import 'editor_edit_source.dart';
import 'editor_edit_state.dart';

class EditorHistoryEntry {
  const EditorHistoryEntry({
    required this.before,
    required this.after,
    required this.label,
    required this.source,
  });

  factory EditorHistoryEntry.fromJson(Map<String, dynamic> json) {
    return EditorHistoryEntry(
      before: _stateFromJson(json['before']),
      after: _stateFromJson(json['after']),
      label: json['label'] is String ? json['label'] as String : 'Edit',
      source: _sourceFromJson(json['source']),
    );
  }

  final EditorEditState before;
  final EditorEditState after;
  final String label;
  final EditorEditSource source;

  Map<String, dynamic> toJson() {
    return {
      'before': before.toJson(),
      'after': after.toJson(),
      'label': label,
      'source': source.name,
    };
  }

  static EditorEditState _stateFromJson(Object? value) {
    if (value is! Map) return EditorEditState.empty();
    return EditorEditState.fromJson(Map<String, dynamic>.from(value));
  }

  static EditorEditSource _sourceFromJson(Object? value) {
    if (value is String) {
      for (final source in EditorEditSource.values) {
        if (source.name == value) return source;
      }
    }
    return EditorEditSource.manual;
  }
}
