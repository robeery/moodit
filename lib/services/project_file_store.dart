import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

typedef ProjectDirectoryProvider = Future<Directory> Function();

class StoredProjectOriginal {
  const StoredProjectOriginal({
    required this.path,
  });

  final String path;
}

class ProjectFileStore {
  ProjectFileStore({
    ProjectDirectoryProvider? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final ProjectDirectoryProvider _documentsDirectoryProvider;

  Future<Directory> projectsRootDirectory() async {
    final documents = await _documentsDirectoryProvider();
    return _ensureDirectory(_join(documents.path, 'projects'));
  }

  Future<Directory> projectDirectory(String projectId) async {
    final safeProjectId = _safeSegment(projectId);
    final root = await projectsRootDirectory();
    return _ensureDirectory(_join(root.path, safeProjectId));
  }

  Future<StoredProjectOriginal> copyOriginalImage({
    required String sourcePath,
    required String projectId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Original image does not exist', sourcePath);
    }

    final projectDir = await projectDirectory(projectId);
    final targetPath = _join(
      projectDir.path,
      'original${_extension(sourcePath)}',
    );
    final copied = await source.copy(targetPath);

    return StoredProjectOriginal(path: copied.path);
  }

  Future<StoredProjectOriginal> moveOriginalImage({
    required String sourcePath,
    required String projectId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Original image does not exist', sourcePath);
    }

    final projectDir = await projectDirectory(projectId);
    final targetPath = _join(
      projectDir.path,
      'original${_extension(sourcePath)}',
    );
    final target = File(targetPath);
    if (await target.exists()) {
      await target.delete();
    }

    try {
      final moved = await source.rename(targetPath);
      return StoredProjectOriginal(path: moved.path);
    } on FileSystemException {
      final copied = await source.copy(targetPath);
      await source.delete();
      return StoredProjectOriginal(path: copied.path);
    }
  }

  Future<String> previewImagePath(String projectId) async {
    final projectDir = await projectDirectory(projectId);
    return _join(projectDir.path, 'preview.jpg');
  }

  Future<String> projectPreviewImagePath({
    required String projectId,
    required String revision,
    String extension = 'jpg',
  }) async {
    final projectDir = await projectDirectory(projectId);
    return _join(
      projectDir.path,
      'preview_${_safeSegment(revision)}.${_safeExtension(extension)}',
    );
  }

  Future<String> versionThumbnailPath({
    required String projectId,
    required String versionId,
  }) async {
    final projectDir = await projectDirectory(projectId);
    final versionsDir = await _ensureDirectory(
      _join(projectDir.path, 'versions'),
    );
    return _join(versionsDir.path, '${_safeSegment(versionId)}.jpg');
  }

  Future<String> writeAiReferenceImageBytes({
    required String projectId,
    required String versionId,
    required Uint8List bytes,
  }) async {
    final path = await aiReferenceImagePath(
      projectId: projectId,
      versionId: versionId,
    );
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> aiReferenceImagePath({
    required String projectId,
    required String versionId,
  }) async {
    final projectDir = await projectDirectory(projectId);
    final referencesDir = await _ensureDirectory(
      _join(projectDir.path, 'ai_references'),
    );
    return _join(referencesDir.path, '${_safeSegment(versionId)}.jpg');
  }

  Future<void> deleteAiReferenceImage({
    required String projectId,
    required String versionId,
  }) async {
    final path = await aiReferenceImagePath(
      projectId: projectId,
      versionId: versionId,
    );
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String?> copyAiReferenceImage({
    required String projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {
    final sourcePath = await aiReferenceImagePath(
      projectId: projectId,
      versionId: sourceVersionId,
    );
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final targetPath = await aiReferenceImagePath(
      projectId: projectId,
      versionId: targetVersionId,
    );
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  Future<void> deleteProjectFiles(String projectId) async {
    final safeProjectId = _safeSegment(projectId);
    final root = await projectsRootDirectory();
    final projectDir = Directory(_join(root.path, safeProjectId));
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }

  static Future<Directory> _ensureDirectory(String path) {
    return Directory(path).create(recursive: true);
  }

  static String _safeSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed == '.' ||
        trimmed == '..') {
      throw ArgumentError.value(value, 'value', 'Invalid path segment');
    }
    return trimmed;
  }

  static String _extension(String path) {
    final slashIndex = path.lastIndexOf('/');
    final backslashIndex = path.lastIndexOf(r'\');
    final separatorIndex =
        slashIndex > backslashIndex ? slashIndex : backslashIndex;
    final dotIndex = path.lastIndexOf('.');

    if (dotIndex <= separatorIndex || dotIndex == path.length - 1) {
      return '';
    }
    return path.substring(dotIndex);
  }

  static String _safeExtension(String value) {
    final extension = value.trim().toLowerCase();
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      throw ArgumentError.value(value, 'value', 'Invalid image extension');
    }
    return extension;
  }

  static String _join(String first, String second) {
    if (first.endsWith('/') || first.endsWith(r'\')) {
      return '$first$second';
    }
    return '$first${Platform.pathSeparator}$second';
  }
}
