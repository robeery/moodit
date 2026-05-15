import '../model/editor_history_entry.dart';

class EditorHistory {
  final List<EditorHistoryEntry> _undoStack = [];
  final List<EditorHistoryEntry> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<EditorHistoryEntry> get entries => List.unmodifiable(_undoStack);

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void push(EditorHistoryEntry entry) {
    if (entry.before.contentEquals(entry.after)) return;

    _undoStack.add(entry);
    _redoStack.clear();
  }

  EditorHistoryEntry? undo() {
    if (_undoStack.isEmpty) return null;

    final entry = _undoStack.removeLast();
    _redoStack.add(entry);
    return entry;
  }

  EditorHistoryEntry? redo() {
    if (_redoStack.isEmpty) return null;

    final entry = _redoStack.removeLast();
    _undoStack.add(entry);
    return entry;
  }
}
