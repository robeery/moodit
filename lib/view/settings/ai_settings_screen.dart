import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../model/ai_profile_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodel/ai_settings_viewmodel.dart';
import '../shared/app_dialog.dart';
import '../shared/app_snack_bar.dart';
import '../shared/app_top_bar.dart';

class AiSettingsScreen extends StatefulWidget {
  final List<AiProfileSettings> initialProfiles;
  final Map<String, String> initialApiKeysByProfileId;
  final String initialActiveProfileId;
  final List<String> availableProviders;
  final List<String> Function(String providerId) modelsForProvider;
  final Future<void> Function(
    AiProfilesUpdate profilesUpdate,
    Map<String, String> apiKeysByProfileId,
  ) onSave;

  const AiSettingsScreen({
    super.key,
    required this.initialProfiles,
    required this.initialApiKeysByProfileId,
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
  late final TextEditingController _apiKeyController;
  late final AiSettingsViewModel _vm;
  late final Map<String, String> _apiKeysByProfileId;
  late String _lastSyncedProfileId;
  final ScrollController _profilesScrollController = ScrollController();
  String? _lastScrolledProfileId;
  bool _obscureApiKey = true;
  bool _isSaving = false;

  // card width 150 + separator 10
  static const double _profileCardExtent = 160;

  @override
  void initState() {
    super.initState();
    _profileNameController = TextEditingController();
    _apiKeyController = TextEditingController();
    _vm = AiSettingsViewModel(
      initialProfiles: widget.initialProfiles,
      initialActiveProfileId: widget.initialActiveProfileId,
      availableProviders: widget.availableProviders,
      modelsForProvider: widget.modelsForProvider,
    );
    _apiKeysByProfileId = Map<String, String>.from(widget.initialApiKeysByProfileId);
    _profileNameController.text = _vm.profileName;
    _lastSyncedProfileId = _vm.selectedProfileId;
    _apiKeyController.text = _apiKeysByProfileId[_vm.selectedProfileId] ?? '';
    _vm.addListener(_syncFields);
  }

  @override
  void dispose() {
    _vm.removeListener(_syncFields);
    _vm.dispose();
    _profileNameController.dispose();
    _apiKeyController.dispose();
    _profilesScrollController.dispose();
    super.dispose();
  }

  void _scrollSelectedProfileIntoView() {
    if (!_profilesScrollController.hasClients) return;
    final index =
        _vm.profiles.indexWhere((p) => p.id == _vm.selectedProfileId);
    if (index < 0) return;

    final position = _profilesScrollController.position;
    final cardStart = index * _profileCardExtent;
    final cardEnd = cardStart + _profileCardExtent;
    final viewStart = position.pixels;
    final viewEnd = viewStart + position.viewportDimension;
    // skip if the card is already fully visible
    if (cardStart >= viewStart && cardEnd <= viewEnd) return;

    final target = cardStart.clamp(0.0, position.maxScrollExtent);
    _profilesScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _syncFields() {
    if (_profileNameController.text != _vm.profileName) {
      _profileNameController.value = TextEditingValue(
        text: _vm.profileName,
        selection: TextSelection.collapsed(offset: _vm.profileName.length),
      );
    }

    final selectedId = _vm.selectedProfileId;
    if (_lastSyncedProfileId == selectedId) return;
    _lastSyncedProfileId = selectedId;

    final nextApiKey = _apiKeysByProfileId[selectedId] ?? '';
    if (_apiKeyController.text == nextApiKey) return;
    _apiKeyController.value = TextEditingValue(
      text: nextApiKey,
      selection: TextSelection.collapsed(offset: nextApiKey.length),
    );
  }

  void _showHint(String message, {bool isError = true}) {
    if (!mounted) return;
    showAppSnackBar(context, message, isError: isError);
  }

  void _commitCurrentProfileApiKey() {
    _apiKeysByProfileId[_vm.selectedProfileId] = _apiKeyController.text;
  }

  void _selectProfile(String profileId) {
    if (profileId == _vm.selectedProfileId) return;
    _commitCurrentProfileApiKey();
    _vm.selectProfile(profileId);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    _commitCurrentProfileApiKey();
    final profilesUpdate = _vm.buildUpdate();
    final validProfileIds = profilesUpdate.profiles.map((p) => p.id).toSet();
    final apiKeysByProfileId = <String, String>{};
    for (final profileId in validProfileIds) {
      apiKeysByProfileId[profileId] =
          (_apiKeysByProfileId[profileId] ?? '').trim();
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(profilesUpdate, apiKeysByProfileId);
      _showHint('AI settings saved.', isError: false);
    } catch (_) {
      _showHint('Failed to save AI settings.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _createProfile() {
    _commitCurrentProfileApiKey();
    final error = _vm.createProfile();
    if (error != null) {
      _showHint(error);
      return;
    }

    _apiKeysByProfileId.putIfAbsent(_vm.selectedProfileId, () => '');
  }

  Future<void> _deleteSelectedProfile() async {
    if (!_vm.canDeleteSelectedProfile) {
      _showHint('At least one AI profile must remain.');
      return;
    }

    final confirmed = await _showDeleteProfileDialog();
    if (confirmed != true) return;

    final deletedId = _vm.selectedProfileId;
    final error = _vm.deleteSelectedProfile();
    if (error != null) {
      _showHint(error);
      return;
    }
    _apiKeysByProfileId.remove(deletedId);
  }

  Future<bool> _showDeleteProfileDialog() {
    return showAppConfirmDialog(
      context,
      title: 'DELETE PROFILE',
      message: 'Are you sure? This cannot be reverted.',
      confirmLabel: 'DELETE',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_lastScrolledProfileId != _vm.selectedProfileId) {
          _lastScrolledProfileId = _vm.selectedProfileId;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollSelectedProfileIntoView(),
          );
        }
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: MooditColors.pageBackground,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AppTopBar(
                    title: 'AI SETTINGS',
                    onBack: () => Navigator.of(context).maybePop(),
                    trailing: TopBarTextAction(
                      label: 'SAVE',
                      enabled: !_isSaving,
                      onTap: _save,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        MooditDims.screenPadding,
                        10,
                        MooditDims.screenPadding,
                        28,
                      ),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACTIVE PROFILE',
                              style: MooditType.sectionLabel,
                            ),
                            Row(
                              children: [
                                _MiniAction(
                                  icon: Icons.add,
                                  label: 'NEW',
                                  onTap: _createProfile,
                                ),
                                const SizedBox(width: 6),
                                _MiniAction(
                                  icon: Icons.delete_outline,
                                  label: 'DELETE',
                                  color: MooditColors.destructive,
                                  onTap: _deleteSelectedProfile,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 104,
                          child: Scrollbar(
                            controller: _profilesScrollController,
                            thumbVisibility: _vm.profiles.length > 1,
                            child: _EdgeFade(
                              child: ListView.separated(
                                controller: _profilesScrollController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(bottom: 10),
                                itemCount: _vm.profiles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, i) {
                                  final profile = _vm.profiles[i];
                                  return _ProfileCard(
                                    name: profile.profileName,
                                    providerId: profile.providerId,
                                    selected:
                                        profile.id == _vm.selectedProfileId,
                                    onTap: () => _selectProfile(profile.id),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel('PROFILE NAME'),
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
                            if (hint != null) _showHint(hint);
                          },
                          style: MooditType.bodyText,
                          cursorColor: MooditColors.baseAccent,
                          decoration: _inputDecoration(
                            counterText:
                                '${_vm.profileName.length}/${AiProfileSettings.maxProfileNameLength}',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FieldLabel('API KEY'),
                            _MiniAction(
                              label: _obscureApiKey ? 'SHOW' : 'HIDE',
                              onTap: () => setState(
                                () => _obscureApiKey = !_obscureApiKey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: MooditType.bodyText,
                          cursorColor: MooditColors.baseAccent,
                          decoration: _inputDecoration(
                            hintText: 'Enter API key for this profile',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('AI PROVIDER'),
                        const SizedBox(height: 8),
                        _Dropdown<String>(
                          value: _vm.selectedProvider,
                          items: _vm.availableProviders,
                          onChanged: _vm.setProvider,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('MODEL'),
                        const SizedBox(height: 8),
                        _Dropdown<String>(
                          value: _vm.selectedModel,
                          items: _vm.availableModels,
                          onChanged: _vm.setModel,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FieldLabel('HISTORY WINDOW'),
                            Text(
                              '${_vm.historyWindowSize} MESSAGES',
                              style: MooditType.monoMeta.copyWith(
                                color: MooditColors.baseAccent,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: _historySliderTheme(),
                          child: Slider(
                            min: AiProfileSettings.minHistoryWindowSize
                                .toDouble(),
                            max: AiProfileSettings.maxHistoryWindowSize
                                .toDouble(),
                            divisions:
                                AiProfileSettings.maxHistoryWindowSize -
                                    AiProfileSettings.minHistoryWindowSize,
                            value: _vm.historyWindowSize.toDouble(),
                            onChanged: _vm.setHistoryWindow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({String? hintText, String? counterText}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(MooditDims.controlRadius),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      hintText: hintText,
      hintStyle: MooditType.bodySecondary.copyWith(color: MooditColors.textOff),
      counterText: counterText,
      counterStyle: MooditType.monoMeta,
      filled: true,
      fillColor: MooditColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(MooditColors.hairline),
      enabledBorder: border(MooditColors.hairline),
      focusedBorder: border(MooditColors.baseAccent),
    );
  }

  SliderThemeData _historySliderTheme() {
    return SliderTheme.of(context).copyWith(
      trackHeight: 2,
      activeTrackColor: MooditColors.baseAccent,
      inactiveTrackColor: MooditColors.hairlineStrong,
      thumbColor: MooditColors.baseAccent,
      overlayColor: MooditColors.baseGlow,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: MooditType.sectionLabel);
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.color = MooditColors.baseAccent,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MooditDims.pillRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: MooditType.monoMeta.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// Fades the horizontal edges so cards that reach the border look cut off,
// hinting that the row can be scrolled.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.03, 0.9, 1.0],
      ).createShader(rect),
      child: child,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.providerId,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String providerId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = aiProviderStartColor(providerId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : MooditColors.card,
          borderRadius: BorderRadius.circular(MooditDims.cardRadius),
          border: Border.all(
            color: selected ? accent : MooditColors.hairline,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: aiProviderGradient(providerId),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MooditType.bodyText,
                ),
                const SizedBox(height: 4),
                Text(aiProviderTag(providerId), style: MooditType.monoMeta),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelForItem,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T item)? labelForItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: MooditColors.card,
        borderRadius: BorderRadius.circular(MooditDims.controlRadius),
        border: Border.all(color: MooditColors.hairline),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: MooditColors.cardAlt,
        borderRadius: BorderRadius.circular(MooditDims.controlRadius),
        style: MooditType.bodyText,
        underline: const SizedBox.shrink(),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: MooditColors.textSecondary,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelForItem != null ? labelForItem!(item) : '$item',
                ),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
