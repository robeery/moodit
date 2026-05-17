import '../model/editor_history_entry.dart';
import '../model/editor_history_snapshot.dart';

class EditorHistory {
  EditorHistory()
      : _undoStack = [],
        _redoStack = [];

  EditorHistory.copyOf(EditorHistory other)
      : _undoStack = List.of(other._undoStack),
        _redoStack = List.of(other._redoStack);

  EditorHistory.fromSnapshot(EditorHistorySnapshot snapshot)
      : _undoStack = List.of(snapshot.undoEntries),
        _redoStack = List.of(snapshot.redoEntries);

  final List<EditorHistoryEntry> _undoStack;
  final List<EditorHistoryEntry> _redoStack;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<EditorHistoryEntry> get entries => List.unmodifiable(_undoStack);
  List<EditorHistoryEntry> get redoEntries => List.unmodifiable(_redoStack);

  EditorHistorySnapshot toSnapshot() {
    return EditorHistorySnapshot(
      undoEntries: List.of(_undoStack),
      redoEntries: List.of(_redoStack),
    );
  }

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
