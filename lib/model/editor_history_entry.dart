import 'editor_edit_source.dart';
import 'editor_edit_state.dart';

class EditorHistoryEntry {
  const EditorHistoryEntry({
    required this.before,
    required this.after,
    required this.label,
    required this.source,
  });

  final EditorEditState before;
  final EditorEditState after;
  final String label;
  final EditorEditSource source;
}
