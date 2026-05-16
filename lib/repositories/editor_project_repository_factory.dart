import '../data/local/app_database.dart';
import 'drift_editor_project_repository.dart';
import 'editor_project_repository.dart';

class EditorProjectRepositoryHandle {
  const EditorProjectRepositoryHandle({
    required this.repository,
    required this.dispose,
  });

  final EditorProjectRepository repository;
  final Future<void> Function() dispose;
}

EditorProjectRepositoryHandle createDefaultEditorProjectRepository() {
  final database = AppDatabase.defaults();
  return EditorProjectRepositoryHandle(
    repository: DriftEditorProjectRepository(database),
    dispose: database.close,
  );
}
