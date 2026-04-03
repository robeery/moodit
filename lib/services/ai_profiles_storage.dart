import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/ai_profile_settings.dart';

class PersistedAiProfiles {
  final List<AiProfileSettings> profiles;
  final String activeProfileId;

  const PersistedAiProfiles({
    required this.profiles,
    required this.activeProfileId,
  });
}

class AiProfilesStorage {
  static const String _payloadKey = 'ai_profiles_payload_v2';
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> _prefs() {
    return _prefsFuture ??= SharedPreferences.getInstance();
  }

  Future<PersistedAiProfiles?> load() async {
    final prefs = await _prefs();
    final payload = prefs.getString(_payloadKey);
    if (payload == null) return null;
    return _parsePayload(payload);
  }

  Future<void> save({
    required List<AiProfileSettings> profiles,
    required String activeProfileId,
  }) async {
    final prefs = await _prefs();
    final payload = jsonEncode({
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'activeProfileId': activeProfileId,
    });
    await prefs.setString(_payloadKey, payload);
  }

  PersistedAiProfiles? _parsePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;

      final rawProfiles = decoded['profiles'];
      if (rawProfiles is! List) return null;

      final profiles = rawProfiles
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(AiProfileSettings.fromJson)
          .toList();

      if (profiles.isEmpty) return null;

      final activeProfileId =
          decoded['activeProfileId'] as String? ?? profiles.first.id;

      return PersistedAiProfiles(
        profiles: profiles,
        activeProfileId: activeProfileId,
      );
    } catch (_) {
      return null;
    }
  }
}
