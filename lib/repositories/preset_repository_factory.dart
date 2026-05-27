import '../data/local/app_database.dart';
import 'drift_preset_repository.dart';
import 'preset_repository.dart';

class PresetRepositoryHandle {
  const PresetRepositoryHandle({
    required this.repository,
    required this.dispose,
  });

  final PresetRepository repository;
  final Future<void> Function() dispose;
}

PresetRepositoryHandle createDefaultPresetRepository() {
  final database = AppDatabase.defaults();
  return PresetRepositoryHandle(
    repository: DriftPresetRepository(database),
    dispose: database.close,
  );
}
