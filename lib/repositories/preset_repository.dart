import '../model/editor_edit_state.dart';
import '../model/editor_preset.dart';

abstract class PresetRepository {
  Future<List<EditorPreset>> loadPresets();

  Future<EditorPreset> createPreset({
    required String name,
    required EditorEditState state,
    required DateTime createdAt,
  });

  Future<EditorPreset> renamePreset({
    required int id,
    required String name,
    required DateTime updatedAt,
  });

  Future<void> deletePreset(int id);
}

class PresetRepositoryException implements Exception {
  const PresetRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PresetValidationException extends PresetRepositoryException {
  const PresetValidationException(super.message);
}

class PresetConflictException extends PresetRepositoryException {
  const PresetConflictException(super.message);
}

class PresetNotFoundException extends PresetRepositoryException {
  const PresetNotFoundException() : super('Preset not found.');
}
