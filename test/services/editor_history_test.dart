import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/editor_edit_source.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_history_entry.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/services/editor_history.dart';

void main() {
  test('history moves entries between undo and redo stacks', () {
    final history = EditorHistory();
    final before = EditorEditState.empty();
    final after = EditorEditState(
      edits: [Edit(type: OperationType.brightness, value: 30)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );

    history.push(EditorHistoryEntry(
      before: before,
      after: after,
      label: 'AI edit',
      source: EditorEditSource.ai,
    ));

    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);

    final undone = history.undo();
    expect(undone?.label, 'AI edit');
    expect(undone?.source, EditorEditSource.ai);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);

    final redone = history.redo();
    expect(redone?.label, 'AI edit');
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
  });

  test('pushing a new entry clears redo', () {
    final history = EditorHistory();
    final empty = EditorEditState.empty();
    final brightness = EditorEditState(
      edits: [Edit(type: OperationType.brightness, value: 30)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );
    final contrast = EditorEditState(
      edits: [Edit(type: OperationType.contrast, value: 10)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );

    history.push(EditorHistoryEntry(
      before: empty,
      after: brightness,
      label: 'Brightness +30',
      source: EditorEditSource.manual,
    ));
    history.undo();

    history.push(EditorHistoryEntry(
      before: empty,
      after: contrast,
      label: 'Contrast +10',
      source: EditorEditSource.manual,
    ));

    expect(history.canRedo, isFalse);
    expect(history.undo()?.label, 'Contrast +10');
  });

  test('copy preserves undo and redo stacks independently', () {
    final history = EditorHistory();
    final empty = EditorEditState.empty();
    final brightness = EditorEditState(
      edits: [Edit(type: OperationType.brightness, value: 30)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );
    final contrast = EditorEditState(
      edits: [Edit(type: OperationType.contrast, value: 10)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );

    history.push(EditorHistoryEntry(
      before: empty,
      after: brightness,
      label: 'Brightness +30',
      source: EditorEditSource.manual,
    ));
    history.push(EditorHistoryEntry(
      before: brightness,
      after: contrast,
      label: 'Contrast +10',
      source: EditorEditSource.manual,
    ));
    history.undo();

    final copy = EditorHistory.copyOf(history);

    expect(copy.canUndo, isTrue);
    expect(copy.canRedo, isTrue);
    expect(copy.undo()?.label, 'Brightness +30');
    expect(history.redo()?.label, 'Contrast +10');
  });

  test('snapshot round trips undo and redo stacks', () {
    final history = EditorHistory();
    final empty = EditorEditState.empty();
    final brightness = EditorEditState(
      edits: [Edit(type: OperationType.brightness, value: 30)],
      colorEdits: const [],
      colorGradingEdits: const [],
    );

    history.push(EditorHistoryEntry(
      before: empty,
      after: brightness,
      label: 'Brightness +30',
      source: EditorEditSource.manual,
    ));
    history.undo();

    final restored = EditorHistory.fromSnapshot(history.toSnapshot());

    expect(restored.canUndo, isFalse);
    expect(restored.canRedo, isTrue);
    expect(restored.redo()?.label, 'Brightness +30');
  });
}
