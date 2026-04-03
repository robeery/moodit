import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../model/ai_profile_settings.dart';
import '../../theme/app_theme.dart';

class AiSettingsScreen extends StatefulWidget {
  final List<AiProfileSettings> initialProfiles;
  final String initialActiveProfileId;
  final List<String> availableProviders;
  final List<String> Function(String providerId) modelsForProvider;
  final ValueChanged<AiProfilesUpdate> onSave;

  const AiSettingsScreen({
    super.key,
    required this.initialProfiles,
    required this.initialActiveProfileId,
    required this.availableProviders,
    required this.modelsForProvider,
    required this.onSave,
  });

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _profileNameController;
  late List<AiProfileSettings> _profiles;
  late String _selectedProfileId;
  late String _selectedProvider;
  late List<String> _availableModels;
  late String _selectedModel;
  late double _historyWindowSize;
  bool _nameLimitHintShown = false;

  AiProfileSettings get _selectedProfile =>
      _profiles.firstWhere((p) => p.id == _selectedProfileId);

  @override
  void initState() {
    super.initState();
    _profileNameController = TextEditingController();
    _profiles = List<AiProfileSettings>.from(widget.initialProfiles);

    if (_profiles.isEmpty) {
      _profiles = [const AiProfileSettings()];
    }

    _selectedProfileId = _profiles.any((p) => p.id == widget.initialActiveProfileId)
        ? widget.initialActiveProfileId
        : _profiles.first.id;

    _loadSelectedProfile();
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  void _loadSelectedProfile() {
    final profile = _selectedProfile;
    _profileNameController.text = profile.profileName;
    _selectedProvider = profile.providerId;
    _historyWindowSize = profile.historyWindowSize.toDouble();
    _syncModelsForProvider(preferredModel: profile.model);
  }

  void _syncModelsForProvider({String? preferredModel}) {
    _availableModels = widget.modelsForProvider(_selectedProvider);
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
    final safeName = _profileNameController.text.trim().isEmpty
        ? AiProfileSettings.defaultProfileName
        : _profileNameController.text.trim();

    _profiles[index] = current.copyWith(
      profileName: safeName,
      providerId: _selectedProvider,
      model: _selectedModel,
      historyWindowSize: _historyWindowSize.round(),
    );
  }

  void _selectProfile(String profileId) {
    if (profileId == _selectedProfileId) return;

    setState(() {
      _commitSelectedProfile();
      _selectedProfileId = profileId;
      _loadSelectedProfile();
    });
  }

  void _createProfile() {
    if (_profiles.length >= AiProfileSettings.maxProfiles) {
      _showErrorHint(
        'Maximum ${AiProfileSettings.maxProfiles} AI profiles reached.',
      );
      return;
    }

    setState(() {
      _commitSelectedProfile();

      final base = _selectedProfile;
      final id = '${DateTime.now().microsecondsSinceEpoch}';
      final name = _nextProfileName();
      final profile = base.copyWith(id: id, profileName: name);

      _profiles.add(profile);
      _selectedProfileId = id;
      _loadSelectedProfile();
    });
  }

  Future<void> _deleteSelectedProfile() async {
    if (_profiles.length <= 1) {
      _showErrorHint('At least one AI profile must remain.');
      return;
    }

    final confirmed = await _showDeleteProfileDialog();
    if (confirmed != true || !mounted) return;

    setState(() {
      final currentIndex =
          _profiles.indexWhere((p) => p.id == _selectedProfileId);
      if (currentIndex < 0) return;

      _profiles.removeAt(currentIndex);
      final nextIndex = currentIndex >= _profiles.length
          ? _profiles.length - 1
          : currentIndex;
      _selectedProfileId = _profiles[nextIndex].id;
      _loadSelectedProfile();
    });
  }

  Future<bool?> _showDeleteProfileDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('DELETE PROFILE', style: AppTextStyles.screenTitle),
        content: const Text(
          'Are you sure? This cannot be reverted.',
          style: TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nextProfileName() {
    final names = _profiles.map((p) => p.profileName).toSet();
    var index = _profiles.length + 1;
    while (names.contains('Profile $index')) {
      index++;
    }
    return 'Profile $index';
  }

  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      _syncModelsForProvider();
    });
  }

  void _saveAndClose() {
    setState(() {
      _commitSelectedProfile();
    });
    widget.onSave(
      AiProfilesUpdate(
        profiles: List<AiProfileSettings>.from(_profiles),
        activeProfileId: _selectedProfileId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('AI settings saved.'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorHint(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.highlight),
        title: const Text('AI SETTINGS', style: AppTextStyles.screenTitle),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.highlight,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('PROFILE', style: AppTextStyles.mutedSmall),
                ),
                TextButton.icon(
                  onPressed: _deleteSelectedProfile,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  label: const Text(
                    'DELETE',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _createProfile,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.highlight),
                  label: const Text(
                    'CREATE',
                    style: TextStyle(
                      color: AppColors.highlight,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            _buildDropdown<String>(
              value: _selectedProfileId,
              items: _profiles.map((p) => p.id).toList(),
              labelForItem: (id) {
                final profile = _profiles.firstWhere((p) => p.id == id);
                return profile.profileName;
              },
              onChanged: _selectProfile,
            ),
            const SizedBox(height: 20),
            const Text('PROFILE NAME', style: AppTextStyles.mutedSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _profileNameController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  AiProfileSettings.maxProfileNameLength,
                ),
              ],
              onChanged: (value) {
                final reachedLimit =
                    value.length >= AiProfileSettings.maxProfileNameLength;
                if (reachedLimit && !_nameLimitHintShown) {
                  _showErrorHint(
                    'Profile name is limited to '
                    '${AiProfileSettings.maxProfileNameLength} characters.',
                  );
                  _nameLimitHintShown = true;
                } else if (!reachedLimit) {
                  _nameLimitHintShown = false;
                }
                setState(() {});
              },
              style: const TextStyle(color: AppColors.accent, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.muted),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.muted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.highlight),
                ),
                counterText:
                    '${_profileNameController.text.length}/${AiProfileSettings.maxProfileNameLength}',
              ),
            ),
            const SizedBox(height: 20),
            const Text('AI PROVIDER', style: AppTextStyles.mutedSmall),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _selectedProvider,
              items: widget.availableProviders,
              onChanged: _onProviderChanged,
            ),
            const SizedBox(height: 20),
            const Text('MODEL', style: AppTextStyles.mutedSmall),
            const SizedBox(height: 6),
            _buildDropdown<String>(
              value: _selectedModel,
              items: _availableModels,
              onChanged: (model) => setState(() => _selectedModel = model),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('HISTORY WINDOW', style: AppTextStyles.mutedSmall),
                Text(
                  '${_historyWindowSize.round()} messages',
                  style: const TextStyle(
                    color: AppColors.highlight,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: AppSliderTheme.of(context),
              child: Slider(
                min: AiProfileSettings.minHistoryWindowSize.toDouble(),
                max: AiProfileSettings.maxHistoryWindowSize.toDouble(),
                divisions: AiProfileSettings.maxHistoryWindowSize -
                    AiProfileSettings.minHistoryWindowSize,
                value: _historyWindowSize,
                onChanged: (value) {
                  setState(() => _historyWindowSize = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T item)? labelForItem,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.muted, width: 0.5),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.accent, fontSize: 13),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.muted),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelForItem != null ? labelForItem(item) : '$item'),
                ))
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
