import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:licenta/model/ai_profile_settings.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/services/ai_profiles_api_key_storage.dart';
import 'package:licenta/services/ai_profiles_storage.dart';
import 'package:licenta/viewmodel/editor_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const connectivityStatusChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity_status');

  test('manual edit can be undone and redone', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityStatusChannel, (_) async => null);
    final sourceFile = await _createTempImage();
    addTearDown(() async {
      final parent = sourceFile.parent;
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });
    final vm = EditorViewModel(
      aiProfilesStorage: _FakeAiProfilesStorage(),
      aiProfilesApiKeyStorage: const _FakeAiProfilesApiKeyStorage(),
    );
    addTearDown(vm.dispose);

    await vm.loadImageFromPath(sourceFile.path);
    vm.beginManualEdit();
    vm.updateEditPreview(Edit(type: OperationType.brightness, value: 30));
    await vm.applyEdit(Edit(type: OperationType.brightness, value: 30));

    expect(vm.getEditValue(OperationType.brightness), 30);
    expect(vm.canUndo, isTrue);
    expect(vm.canRedo, isFalse);

    final undoResult = await vm.undo();
    expect(undoResult?.label, 'Brightness +30');
    expect(vm.getEditValue(OperationType.brightness), 0);
    expect(vm.canRedo, isTrue);

    final redoResult = await vm.redo();
    expect(redoResult?.label, 'Brightness +30');
    expect(vm.getEditValue(OperationType.brightness), 30);
  });
}

Future<File> _createTempImage() async {
  final tempDir = await Directory.systemTemp.createTemp('moodit_history_test_');
  final image = img.Image(width: 16, height: 16, numChannels: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, 40 + x, 70 + y, 120, 255);
    }
  }

  final sourceFile = File('${tempDir.path}/source.png');
  await sourceFile.writeAsBytes(Uint8List.fromList(img.encodePng(image)));
  return sourceFile;
}

class _FakeAiProfilesStorage extends AiProfilesStorage {
  @override
  Future<PersistedAiProfiles?> load() async => null;

  @override
  Future<void> save({
    required List<AiProfileSettings> profiles,
    required String activeProfileId,
  }) async {}
}

class _FakeAiProfilesApiKeyStorage extends AiProfilesApiKeyStorage {
  const _FakeAiProfilesApiKeyStorage();

  @override
  Future<Map<String, String>> readMany(Iterable<String> profileIds) async => {};

  @override
  Future<void> saveForProfiles({
    required Map<String, String> apiKeysByProfileId,
    required Set<String> validProfileIds,
  }) async {}
}
