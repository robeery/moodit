import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiProfilesApiKeyStorage {
  static const String _keyPrefix = 'ai_profile_api_key_';

  final FlutterSecureStorage _storage;

  const AiProfilesApiKeyStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  String _storageKeyForProfile(String profileId) => '$_keyPrefix$profileId';

  Future<Map<String, String>> readMany(Iterable<String> profileIds) async {
    final keys = <String, String>{};
    for (final profileId in profileIds) {
      final trimmedId = profileId.trim();
      if (trimmedId.isEmpty) continue;
      final value = await _storage.read(key: _storageKeyForProfile(trimmedId));
      if (value == null) continue;
      final safeValue = value.trim();
      if (safeValue.isEmpty) continue;
      keys[trimmedId] = safeValue;
    }
    return keys;
  }

  Future<void> saveForProfiles({
    required Map<String, String> apiKeysByProfileId,
    required Set<String> validProfileIds,
  }) async {
    final trimmedValidIds = validProfileIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final all = await _storage.readAll();
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_keyPrefix)) continue;
      final profileId = entry.key.substring(_keyPrefix.length);
      if (!trimmedValidIds.contains(profileId)) {
        await _storage.delete(key: entry.key);
      }
    }

    for (final profileId in trimmedValidIds) {
      final keyValue = apiKeysByProfileId[profileId]?.trim() ?? '';
      final storageKey = _storageKeyForProfile(profileId);
      if (keyValue.isEmpty) {
        await _storage.delete(key: storageKey);
      } else {
        await _storage.write(key: storageKey, value: keyValue);
      }
    }
  }
}
