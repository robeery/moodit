import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/data/local/app_database.dart';
import 'package:licenta/data/local/mappers/editor_project_record_mapper.dart';
import 'package:licenta/data/local/mappers/editor_version_record_mapper.dart';
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_edit_source.dart';
import 'package:licenta/model/editor_history_entry.dart';
import 'package:licenta/model/editor_history_snapshot.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';

void main() {
  test('project model maps to Drift companion', () {
    final createdAt = DateTime.utc(2026, 5, 16, 9);
    final updatedAt = DateTime.utc(2026, 5, 16, 10);
    final openedAt = DateTime.utc(2026, 5, 16, 11);
    final state = _editState();
    final project = EditorProject(
	      id: 1,
	      name: 'Portrait',
	      status: EditorProjectStatus.saved,
	      activeVersionId: 'version-1',
	      originalImagePath: '/projects/project-1/original.jpg',
      previewImagePath: '/projects/project-1/preview.jpg',
      currentState: state,
      originalWidth: 4000,
      originalHeight: 3000,
      previewWidth: 1080,
      previewHeight: 810,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: openedAt,
    );

    final companion = project.toRecordCompanion();

    expect(companion.id.value, project.id);
	    expect(companion.name.value, project.name);
	    expect(companion.status.value, EditorProjectStatus.saved.storageValue);
	    expect(companion.activeVersionId.value, 'version-1');
	    expect(companion.originalImagePath.value, project.originalImagePath);
    expect(companion.previewImagePath.value, project.previewImagePath);
    expect(companion.currentStateJson.value, state.toJsonString());
    expect(companion.originalWidth.value, 4000);
    expect(companion.originalHeight.value, 3000);
    expect(companion.previewWidth.value, 1080);
    expect(companion.previewHeight.value, 810);
    expect(companion.createdAt.value, createdAt);
    expect(companion.updatedAt.value, updatedAt);
    expect(companion.lastOpenedAt.value, openedAt);
  });

  test('project Drift record maps to app model', () {
    final createdAt = DateTime.utc(2026, 5, 16, 9);
    final updatedAt = DateTime.utc(2026, 5, 16, 10);
    final openedAt = DateTime.utc(2026, 5, 16, 11);
    final state = _editState();
    final record = EditorProjectRecord(
	      id: 1,
	      name: 'Portrait',
	      status: EditorProjectStatus.saved.storageValue,
	      activeVersionId: 'version-1',
	      originalImagePath: '/projects/project-1/original.jpg',
      previewImagePath: '/projects/project-1/preview.jpg',
      currentStateJson: state.toJsonString(),
      originalWidth: 4000,
      originalHeight: 3000,
      previewWidth: 1080,
      previewHeight: 810,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: openedAt,
    );

    final project = record.toModel();

    expect(project.id, record.id);
	    expect(project.name, record.name);
	    expect(project.status, EditorProjectStatus.saved);
	    expect(project.activeVersionId, 'version-1');
	    expect(project.originalImagePath, record.originalImagePath);
    expect(project.previewImagePath, record.previewImagePath);
    expect(project.currentState.contentEquals(state), isTrue);
    expect(project.originalWidth, record.originalWidth);
    expect(project.originalHeight, record.originalHeight);
    expect(project.previewWidth, record.previewWidth);
    expect(project.previewHeight, record.previewHeight);
    expect(project.createdAt, createdAt);
    expect(project.updatedAt, updatedAt);
    expect(project.lastOpenedAt, openedAt);
  });

  test('unknown project status maps to draft', () {
    final createdAt = DateTime.utc(2026, 5, 16, 9);
    final record = EditorProjectRecord(
	      id: 1,
	      name: 'Portrait',
	      status: 'old-or-invalid',
	      activeVersionId: null,
	      originalImagePath: '/projects/project-1/original.jpg',
      previewImagePath: null,
      currentStateJson: EditorEditState.empty().toJsonString(),
      originalWidth: 4000,
      originalHeight: 3000,
      previewWidth: 1080,
      previewHeight: 810,
      createdAt: createdAt,
      updatedAt: createdAt,
      lastOpenedAt: null,
    );

    final project = record.toModel();

    expect(project.status, EditorProjectStatus.draft);
  });

	  test('version model maps to Drift companion', () {
	    final createdAt = DateTime.utc(2026, 5, 16, 12);
	    final state = _editState();
	    final history = _historySnapshot(state);
	    final version = EditorVersion(
	      id: 'version-1',
	      projectId: 1,
	      name: 'Version 1',
	      parentVersionId: 'version-0',
	      state: state,
	      history: history,
	      thumbnailPath: '/projects/project-1/versions/version-1.jpg',
      sortOrder: 1,
      createdAt: createdAt,
    );

    final companion = version.toRecordCompanion();

    expect(companion.id.value, version.id);
	    expect(companion.projectId.value, version.projectId);
	    expect(companion.name.value, version.name);
	    expect(companion.parentVersionId.value, 'version-0');
	    expect(companion.stateJson.value, state.toJsonString());
	    expect(companion.historyJson.value, history.toJsonString());
	    expect(companion.thumbnailPath.value, version.thumbnailPath);
    expect(companion.sortOrder.value, version.sortOrder);
    expect(companion.createdAt.value, createdAt);
  });

	  test('version Drift record maps to app model', () {
	    final createdAt = DateTime.utc(2026, 5, 16, 12);
	    final state = _editState();
	    final history = _historySnapshot(state);
	    final record = EditorVersionRecord(
	      id: 'version-1',
	      projectId: 1,
	      name: 'Version 1',
	      parentVersionId: 'version-0',
	      stateJson: state.toJsonString(),
	      historyJson: history.toJsonString(),
	      thumbnailPath: '/projects/project-1/versions/version-1.jpg',
      sortOrder: 1,
      createdAt: createdAt,
    );

    final version = record.toModel();

    expect(version.id, record.id);
	    expect(version.projectId, record.projectId);
	    expect(version.name, record.name);
	    expect(version.parentVersionId, 'version-0');
	    expect(version.state.contentEquals(state), isTrue);
	    expect(version.history.undoEntries.single.label, 'Brightness +20');
	    expect(version.thumbnailPath, record.thumbnailPath);
    expect(version.sortOrder, record.sortOrder);
    expect(version.createdAt, createdAt);
  });
}

EditorHistorySnapshot _historySnapshot(EditorEditState after) {
  return EditorHistorySnapshot(
    undoEntries: [
      EditorHistoryEntry(
        before: EditorEditState.empty(),
        after: after,
        label: 'Brightness +20',
        source: EditorEditSource.manual,
      ),
    ],
    redoEntries: const [],
  );
}

EditorEditState _editState() {
  return EditorEditState(
    edits: [
      Edit(type: OperationType.brightness, value: 20),
      Edit(type: OperationType.blur, value: 12),
    ],
    colorEdits: [
      ColorEdit(range: ColorRange.red, saturation: 15),
    ],
    colorGradingEdits: [
      ColorGradingEdit(zone: ColorGradingZone.shadows, hue: 220, strength: 18),
    ],
  );
}
