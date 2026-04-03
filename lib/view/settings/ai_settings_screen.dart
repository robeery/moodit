import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../model/ai_profile_settings.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/ai_settings_viewmodel.dart';

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
  late final AiSettingsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _profileNameController = TextEditingController();
    _vm = AiSettingsViewModel(
      initialProfiles: widget.initialProfiles,
      initialActiveProfileId: widget.initialActiveProfileId,
      availableProviders: widget.availableProviders,
      modelsForProvider: widget.modelsForProvider,
    );
    _profileNameController.text = _vm.profileName;
    _vm.addListener(_syncProfileNameField);
  }

  @override
  void dispose() {
    _vm.removeListener(_syncProfileNameField);
    _vm.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  void _syncProfileNameField() {
    if (_profileNameController.text == _vm.profileName) return;
    _profileNameController.value = TextEditingValue(
      text: _vm.profileName,
      selection: TextSelection.collapsed(offset: _vm.profileName.length),
    );
  }

  void _showHint(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade900 : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _save() {
    final update = _vm.buildUpdate();
    widget.onSave(update);
    _showHint('AI settings saved.', isError: false);
  }

  void _createProfile() {
    final error = _vm.createProfile();
    if (error != null) {
      _showHint(error);
    }
  }

  Future<void> _deleteSelectedProfile() async {
    if (!_vm.canDeleteSelectedProfile) {
      _showHint('At least one AI profile must remain.');
      return;
    }

    final confirmed = await _showDeleteProfileDialog();
    if (confirmed != true) return;

    final error = _vm.deleteSelectedProfile();
    if (error != null) {
      _showHint(error);
    }
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            iconTheme: const IconThemeData(color: AppColors.highlight),
            title: const Text('AI SETTINGS', style: AppTextStyles.screenTitle),
            actions: [
              TextButton(
                onPressed: _save,
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
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.highlight,
                      ),
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
                  value: _vm.selectedProfileId,
                  items: _vm.profiles.map((p) => p.id).toList(),
                  labelForItem: (id) {
                    final profile = _vm.profiles.firstWhere((p) => p.id == id);
                    return profile.profileName;
                  },
                  onChanged: _vm.selectProfile,
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
                    final hint = _vm.setProfileName(value);
                    if (hint != null) {
                      _showHint(hint);
                    }
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
                        '${_vm.profileName.length}/${AiProfileSettings.maxProfileNameLength}',
                  ),
                ),
                const SizedBox(height: 20),
                const Text('AI PROVIDER', style: AppTextStyles.mutedSmall),
                const SizedBox(height: 6),
                _buildDropdown<String>(
                  value: _vm.selectedProvider,
                  items: _vm.availableProviders,
                  onChanged: _vm.setProvider,
                ),
                const SizedBox(height: 20),
                const Text('MODEL', style: AppTextStyles.mutedSmall),
                const SizedBox(height: 6),
                _buildDropdown<String>(
                  value: _vm.selectedModel,
                  items: _vm.availableModels,
                  onChanged: _vm.setModel,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HISTORY WINDOW', style: AppTextStyles.mutedSmall),
                    Text(
                      '${_vm.historyWindowSize} messages',
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
                    value: _vm.historyWindowSize.toDouble(),
                    onChanged: _vm.setHistoryWindow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
