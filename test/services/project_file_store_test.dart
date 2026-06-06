import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/services/project_file_store.dart';

void main() {
  test('copies original image into app-owned project folder', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final source = File('${tempDir.path}/source.PNG');
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    await source.writeAsBytes(bytes);
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );

    final original = await store.copyOriginalImage(
      sourcePath: source.path,
      projectId: 'project-1',
    );

    expect(original.path, endsWith('${Platform.pathSeparator}original.PNG'));
    expect(await File(original.path).readAsBytes(), bytes);
    expect(original.path, isNot(source.path));
  });

  test('creates stable preview and version thumbnail paths', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );

    final previewPath = await store.previewImagePath('project-1');
    final revisedPreviewPath = await store.projectPreviewImagePath(
      projectId: 'project-1',
      revision: '123_1',
    );
    final thumbnailPath = await store.versionThumbnailPath(
      projectId: 'project-1',
      versionId: 'version-1',
    );

    expect(previewPath, endsWith('${Platform.pathSeparator}preview.jpg'));
    expect(
      revisedPreviewPath,
      endsWith('${Platform.pathSeparator}preview_123_1.jpg'),
    );
    expect(
      thumbnailPath,
      endsWith(
        '${Platform.pathSeparator}versions'
        '${Platform.pathSeparator}version-1.jpg',
      ),
    );
    expect(await Directory('${tempDir.path}/projects/project-1').exists(), isTrue);
    expect(
      await Directory('${tempDir.path}/projects/project-1/versions').exists(),
      isTrue,
    );
  });

  test('moves original image into final project folder', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final source = File('${tempDir.path}/source.jpg');
    final bytes = Uint8List.fromList([9, 8, 7, 6]);
    await source.writeAsBytes(bytes);
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );

    final original = await store.moveOriginalImage(
      sourcePath: source.path,
      projectId: '1',
    );

    expect(original.path, endsWith('${Platform.pathSeparator}original.jpg'));
    expect(
      original.path,
      contains('${Platform.pathSeparator}1${Platform.pathSeparator}'),
    );
    expect(await File(original.path).readAsBytes(), bytes);
    expect(await source.exists(), isFalse);
  });

  test('deletes project folder recursively', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );
    final thumbnailPath = await store.versionThumbnailPath(
      projectId: 'project-1',
      versionId: 'version-1',
    );
    await File(thumbnailPath).writeAsBytes([1, 2, 3]);

    await store.deleteProjectFiles('project-1');

    expect(await Directory('${tempDir.path}/projects/project-1').exists(), isFalse);
  });

  test('writes, copies, and deletes AI reference images', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );
    final bytes = Uint8List.fromList([7, 8, 9]);

    final referencePath = await store.writeAiReferenceImageBytes(
      projectId: 'project-1',
      versionId: 'version-1',
      bytes: bytes,
    );
    final copiedPath = await store.copyAiReferenceImage(
      projectId: 'project-1',
      sourceVersionId: 'version-1',
      targetVersionId: 'version-2',
    );

    expect(
      referencePath,
      endsWith(
        '${Platform.pathSeparator}ai_references'
        '${Platform.pathSeparator}version-1.jpg',
      ),
    );
    expect(await File(referencePath).readAsBytes(), bytes);
    expect(copiedPath, isNotNull);
    expect(await File(copiedPath!).readAsBytes(), bytes);

    await store.deleteAiReferenceImage(
      projectId: 'project-1',
      versionId: 'version-1',
    );

    expect(await File(referencePath).exists(), isFalse);
    expect(await File(copiedPath).exists(), isTrue);
  });

  test('rejects invalid path segments', () async {
    final tempDir = await Directory.systemTemp.createTemp('moodit_files_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final store = ProjectFileStore(
      documentsDirectoryProvider: () async => tempDir,
    );

    expect(
      store.projectDirectory('../bad'),
      throwsArgumentError,
    );
  });
}
