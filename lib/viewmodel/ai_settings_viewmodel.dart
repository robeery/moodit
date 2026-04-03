import 'package:flutter/foundation.dart';
import '../model/ai_profile_settings.dart';

typedef ModelsForProvider = List<String> Function(String providerId);

class AiSettingsViewModel extends ChangeNotifier {
  final List<String> _availableProviders;
  final ModelsForProvider _modelsForProvider;

  List<AiProfileSettings> _profiles;
  String _selectedProfileId;

  String _selectedProvider = AiProfileSettings.geminiProviderId;
  List<String> _availableModels = const [AiProfileSettings.defaultModel];
  String _selectedModel = AiProfileSettings.defaultModel;
  int _historyWindowSize = AiProfileSettings.defaultHistoryWindowSize;
  String _profileName = AiProfileSettings.defaultProfileName;
  bool _nameLimitHintShown = false;

  AiSettingsViewModel({
    required List<AiProfileSettings> initialProfiles,
    required String initialActiveProfileId,
    required List<String> availableProviders,
    required ModelsForProvider modelsForProvider,
  })  : _profiles = List<AiProfileSettings>.from(initialProfiles),
        _selectedProfileId = initialActiveProfileId,
        _availableProviders = List<String>.from(availableProviders),
        _modelsForProvider = modelsForProvider {
    if (_profiles.isEmpty) {
      _profiles = [const AiProfileSettings()];
    }

    if (!_profiles.any((p) => p.id == _selectedProfileId)) {
      _selectedProfileId = _profiles.first.id;
    }

    _loadSelectedProfile();
  }

  List<AiProfileSettings> get profiles => List.unmodifiable(_profiles);
  List<String> get availableProviders => List.unmodifiable(_availableProviders);
  List<String> get availableModels => List.unmodifiable(_availableModels);
  String get selectedProfileId => _selectedProfileId;
  String get selectedProvider => _selectedProvider;
  String get selectedModel => _selectedModel;
  int get historyWindowSize => _historyWindowSize;
  String get profileName => _profileName;
  bool get canDeleteSelectedProfile => _profiles.length > 1;

  void selectProfile(String profileId) {
    if (profileId == _selectedProfileId) return;
    _commitSelectedProfile();
    _selectedProfileId = profileId;
    _loadSelectedProfile();
    notifyListeners();
  }

  String? createProfile() {
    if (_profiles.length >= AiProfileSettings.maxProfiles) {
      return 'Maximum ${AiProfileSettings.maxProfiles} AI profiles reached.';
    }

    _commitSelectedProfile();
    final base = _selectedProfile();
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final name = _nextProfileName();
    final profile = base.copyWith(id: id, profileName: name);
    _profiles.add(profile);
    _selectedProfileId = id;
    _loadSelectedProfile();
    notifyListeners();
    return null;
  }

  String? deleteSelectedProfile() {
    if (_profiles.length <= 1) {
      return 'At least one AI profile must remain.';
    }

    final currentIndex =
        _profiles.indexWhere((p) => p.id == _selectedProfileId);
    if (currentIndex < 0) {
      return 'Unable to delete the selected profile.';
    }

    _profiles.removeAt(currentIndex);
    final nextIndex =
        currentIndex >= _profiles.length ? _profiles.length - 1 : currentIndex;
    _selectedProfileId = _profiles[nextIndex].id;
    _loadSelectedProfile();
    notifyListeners();
    return null;
  }

  String? setProfileName(String value) {
    _profileName = value;
    final reachedLimit =
        value.length >= AiProfileSettings.maxProfileNameLength;

    String? hint;
    if (reachedLimit && !_nameLimitHintShown) {
      hint = 'Profile name is limited to '
          '${AiProfileSettings.maxProfileNameLength} characters.';
      _nameLimitHintShown = true;
    } else if (!reachedLimit) {
      _nameLimitHintShown = false;
    }

    notifyListeners();
    return hint;
  }

  void setProvider(String provider) {
    if (_selectedProvider == provider) return;
    _selectedProvider = provider;
    _syncModelsForProvider();
    notifyListeners();
  }

  void setModel(String model) {
    if (!_availableModels.contains(model)) return;
    if (_selectedModel == model) return;
    _selectedModel = model;
    notifyListeners();
  }

  void setHistoryWindow(double value) {
    final next = value
        .round()
        .clamp(
          AiProfileSettings.minHistoryWindowSize,
          AiProfileSettings.maxHistoryWindowSize,
        )
        .toInt();
    if (_historyWindowSize == next) return;
    _historyWindowSize = next;
    notifyListeners();
  }

  AiProfilesUpdate buildUpdate() {
    _commitSelectedProfile();
    notifyListeners();
    return AiProfilesUpdate(
      profiles: List<AiProfileSettings>.from(_profiles),
      activeProfileId: _selectedProfileId,
    );
  }

  AiProfileSettings _selectedProfile() {
    final index = _profiles.indexWhere((p) => p.id == _selectedProfileId);
    if (index >= 0) return _profiles[index];
    return _profiles.first;
  }

  void _loadSelectedProfile() {
    final profile = _selectedProfile();
    _profileName = profile.profileName;
    _selectedProvider = profile.providerId;
    _historyWindowSize = profile.historyWindowSize;
    _nameLimitHintShown = false;
    _syncModelsForProvider(preferredModel: profile.model);
  }

  void _syncModelsForProvider({String? preferredModel}) {
    _availableModels = _modelsForProvider(_selectedProvider);
    if (_availableModels.isEmpty) {
      _availableModels = [AiProfileSettings.defaultModel];
    }

    final desiredModel = preferredModel ?? _selectedModel;
    _selectedModel = _availableModels.contains(desiredModel)
        ? desiredModel
        : _availableModels.first;
  }

  void _commitSelectedProfile() {
    final index = _profiles.indexWhere((p) => p.id == _selectedProfileId);
    if (index == -1) return;

    final current = _profiles[index];
    final safeName = _profileName.trim().isEmpty
        ? AiProfileSettings.defaultProfileName
        : _profileName.trim();

    _profiles[index] = current.copyWith(
      profileName: safeName,
      providerId: _selectedProvider,
      model: _selectedModel,
      historyWindowSize: _historyWindowSize,
    );
    _profileName = safeName;
  }

  String _nextProfileName() {
    final names = _profiles.map((p) => p.profileName).toSet();
    var index = _profiles.length + 1;
    while (names.contains('Profile $index')) {
      index++;
    }
    return 'Profile $index';
  }
}
