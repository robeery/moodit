import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/editor_project.dart';

void main() {
  test('unnamed draft displays as draft but saves with project fallback', () {
    final draft = _project(
      id: 12,
      name: unnamedDraftProjectName,
      status: EditorProjectStatus.draft,
    );

    expect(displayProjectName(draft), unnamedDraftProjectName);
    expect(suggestedSavedProjectName(draft), 'Project 12');
  });

  test('legacy generated draft names are hidden from user-facing labels', () {
    final draft = _project(
      id: 3,
      name: '100000000123',
      status: EditorProjectStatus.draft,
    );

    expect(displayProjectName(draft), unnamedDraftProjectName);
    expect(suggestedSavedProjectName(draft), 'Project 3');
  });

  test('custom draft names are preserved', () {
    final draft = _project(
      id: 5,
      name: 'Portrait draft',
      status: EditorProjectStatus.draft,
    );

    expect(displayProjectName(draft), 'Portrait draft');
    expect(suggestedSavedProjectName(draft), 'Portrait draft');
  });
}

EditorProject _project({
  required int id,
  required String name,
  required EditorProjectStatus status,
}) {
  final createdAt = DateTime.utc(2026, 5, 18, 10);
  return EditorProject(
    id: id,
    name: name,
    status: status,
    originalImagePath: '/tmp/project_$id.jpg',
    currentState: EditorEditState.empty(),
    originalWidth: 16,
    originalHeight: 16,
    previewWidth: 16,
    previewHeight: 16,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
