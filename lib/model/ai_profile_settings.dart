class AiProfileSettings {
  static const String geminiProviderId = 'Gemini';
  static const String defaultProfileId = 'default';
  static const String defaultProfileName = 'Default Profile';
  static const String defaultModel = 'gemini-2.5-flash-lite';
  static const int defaultHistoryWindowSize = 10;
  static const int minHistoryWindowSize = 1;
  static const int maxHistoryWindowSize = 30;
  static const int maxProfiles = 10;
  static const int maxProfileNameLength = 32;

  final String id;
  final String profileName;
  final String providerId;
  final String model;
  final int historyWindowSize;

  const AiProfileSettings({
    this.id = defaultProfileId,
    this.profileName = defaultProfileName,
    this.providerId = geminiProviderId,
    this.model = defaultModel,
    this.historyWindowSize = defaultHistoryWindowSize,
  });

  factory AiProfileSettings.fromJson(Map<String, dynamic> json) {
    return AiProfileSettings(
      id: json['id'] as String? ?? defaultProfileId,
      profileName: json['profileName'] as String? ?? defaultProfileName,
      providerId: json['providerId'] as String? ?? geminiProviderId,
      model: json['model'] as String? ?? defaultModel,
      historyWindowSize:
          json['historyWindowSize'] as int? ?? defaultHistoryWindowSize,
    );
  }

  AiProfileSettings copyWith({
    String? id,
    String? profileName,
    String? providerId,
    String? model,
    int? historyWindowSize,
  }) {
    return AiProfileSettings(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      historyWindowSize: historyWindowSize ?? this.historyWindowSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileName': profileName,
        'providerId': providerId,
        'model': model,
        'historyWindowSize': historyWindowSize,
      };
}

class AiProfilesUpdate {
  final List<AiProfileSettings> profiles;
  final String activeProfileId;

  const AiProfilesUpdate({
    required this.profiles,
    required this.activeProfileId,
  });
}
