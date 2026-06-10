import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../../model/editor_version.dart';
import '../../model/editor_preset.dart';
import '../../model/export_option.dart';
import '../../repositories/preset_repository.dart';
import '../../viewmodel/editor_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../projects/project_details_screen.dart';
import '../presets/my_presets_screen.dart';
import '../settings/ai_settings_screen.dart';
import 'widgets/editor_drawer.dart';
import 'widgets/history_action_bar.dart';
import 'widgets/pending_edits_bar.dart';
import 'widgets/image_viewer.dart';
import 'widgets/tbd_dialog.dart';
import 'panels/basic_edit_panel.dart';
import 'panels/color_edit_panel.dart';
import 'panels/grading_edit_panel.dart';
import 'panels/chat_panel.dart';
import 'widgets/mode_tab_bar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    this.importImagePath,
    this.projectId,
  }) : assert(importImagePath == null || projectId == null);

  final String? importImagePath;
  final int? projectId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const Duration _initialLoadDelay = Duration(milliseconds: 320);

  final EditorViewModel _vm = EditorViewModel();
  bool _savedBannerVisible = false;
  bool _savedBannerOpaque = false;
  bool _historyActionVisible = false;
  String _historyActionMessage = '';
  IconData _historyActionIcon = Icons.undo;
  Timer? _historyActionHideTimer;
  Timer? _historyActionClearTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startInitialLoad());
    });
  }

  Future<void> _startInitialLoad() async {
    await Future<void>.delayed(_initialLoadDelay);
    if (!mounted) return;

    final importImagePath = widget.importImagePath;
    if (importImagePath != null) {
      await _importInitialImage(importImagePath);
      return;
    }

    final projectId = widget.projectId;
    if (projectId != null) {
      await _loadInitialProject(projectId);
    }
  }

  Future<void> _importInitialImage(String imagePath) async {
    try {
      await _vm.importImageAsProject(imagePath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not import photo.'),
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadInitialProject(int projectId) async {
    try {
      final loaded = await _vm.loadProject(projectId);
      if (loaded || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not open project.'),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _historyActionHideTimer?.cancel();
    _historyActionClearTimer?.cancel();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          endDrawer: EditorDrawer(
            onOpenAiSettings: _openAiSettings,
            onOpenProjectSettings: _openProjectSettings,
            onOpenPresets: _openPresets,
            showProjectSettings: _vm.hasPersistedProject,
            canOpenProjectSettings: _vm.canOpenProjectSettings,
            canOpenPresets: _vm.canUsePresets,
            canSavePreset: _vm.canSavePreset,
            onExport: _handleExport,
            exportSettings: _vm.exportSettings,
            onExportSettingsChanged: _vm.updateExportSettings,
          ),
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppColors.highlight),
            title: const Text('EDIT', style: AppTextStyles.screenTitle),
            centerTitle: true,
            actions: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.accent),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _vm.hasImage
                ? KeyedSubtree(
                    key: const ValueKey('editor'),
                    child: _buildEditor(),
                  )
                : KeyedSubtree(
                    key: const ValueKey('editor-loading'),
                    child: _buildLoadingState(),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Future<void> _handleExport(ExportOption option) async {
    if (!option.implemented) {
      showTbdDialog(context);
      return;
    }

    if (!_vm.hasImage) return;

    if (option == ExportOption.project) {
      await _showSaveProjectDialog();
      return;
    }

    if (option == ExportOption.preset) {
      await _showSavePresetDialog();
      return;
    }

    if (option != ExportOption.gallery) {
      showTbdDialog(context);
      return;
    }

    var exportDialogVisible = false;
    try {
      final exportFuture = _vm.exportToGallery();
      _showExportingDialog();
      exportDialogVisible = true;
      await exportFuture;
      if (mounted) {
        if (exportDialogVisible) {
          Navigator.of(context, rootNavigator: true).pop();
          exportDialogVisible = false;
        }
        setState(() { _savedBannerVisible = true; _savedBannerOpaque = true; });
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _savedBannerOpaque = false);
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _savedBannerVisible = false);
          });
        });
      }
    } on GalException catch (e) {
      if (mounted) {
        if (exportDialogVisible) {
          Navigator.of(context, rootNavigator: true).pop();
          exportDialogVisible = false;
        }
        final message = switch (e.type) {
          GalExceptionType.accessDenied => 'Permission denied. Please enable gallery access in Settings.',
          GalExceptionType.notSupportedFormat => 'Unsupported image format.',
          GalExceptionType.notEnoughSpace => 'Not enough storage space.',
          GalExceptionType.unexpected => 'Unexpected error occurred.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (exportDialogVisible) {
          Navigator.of(context, rootNavigator: true).pop();
          exportDialogVisible = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted && exportDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showExportingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final progress = _vm.exportProgress ?? 0.0;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            content: SizedBox(
              width: 240,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  final percent = (animatedProgress * 100).round().clamp(0, 100);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.highlight,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'EXPORTING...',
                              style: TextStyle(color: AppColors.accent, fontSize: 12, letterSpacing: 2),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: animatedProgress,
                        color: AppColors.highlight,
                        backgroundColor: AppColors.bg,
                        minHeight: 3,
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSaveProjectDialog() async {
    final controller = TextEditingController(text: _vm.defaultProjectName);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('SAVE AS PROJECT', style: AppTextStyles.screenTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
          cursorColor: AppColors.highlight,
          decoration: const InputDecoration(
            labelText: 'PROJECT NAME',
            labelStyle: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.muted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.highlight),
            ),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null) return;

    final saved = await _vm.saveCurrentDraftAsProject(name);
    if (!mounted || !saved) return;
    _showHistoryActionBar(
      message: 'Project saved: ${_vm.currentProject?.name ?? name.trim()}',
      icon: Icons.folder_outlined,
    );
  }

  Future<void> _showSavePresetDialog() async {
    String defaultName;
    try {
      defaultName = await _vm.defaultPresetName();
    } on PresetRepositoryException catch (error) {
      _showPresetError(error.message);
      return;
    } catch (_) {
      _showPresetError('Could not load presets.');
      return;
    }
    if (!mounted) return;

    final controller = TextEditingController(text: defaultName);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('SAVE AS PRESET', style: AppTextStyles.screenTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: editorPresetNameMaxLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(editorPresetNameMaxLength),
          ],
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
          cursorColor: AppColors.highlight,
          decoration: const InputDecoration(
            labelText: 'PRESET NAME',
            counterText: '',
            labelStyle: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.muted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.highlight),
            ),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null) return;

    try {
      final preset = await _vm.saveCurrentPreset(name);
      if (!mounted) return;
      _showHistoryActionBar(
        message: 'Preset saved: ${preset.name}',
        icon: Icons.layers_outlined,
      );
    } on PresetRepositoryException catch (error) {
      _showPresetError(error.message);
    } catch (_) {
      _showPresetError('Could not save preset.');
    }
  }

  Future<void> _openPresets() async {
    if (!_vm.canUsePresets) return;

    final preset = await Navigator.of(context).push<EditorPreset>(
      MaterialPageRoute(
        builder: (_) => MyPresetsScreen(
          selectionMode: true,
          thumbnailSourceFrame: _vm.presetThumbnailSourceFrame,
        ),
      ),
    );
    if (!mounted || preset == null) return;

    final mode = await _showPresetApplyModeDialog(preset.name);
    if (!mounted || mode == null) return;

    final result = await _vm.applyPreset(preset, mode);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset already applied.'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _showHistoryActionBar(
      message: switch (mode) {
        PresetApplyMode.merge => 'Preset merged: ${preset.name}',
        PresetApplyMode.replace => 'Replaced with preset: ${preset.name}',
      },
      icon: Icons.layers_outlined,
    );
  }

  Future<PresetApplyMode?> _showPresetApplyModeDialog(String presetName) {
    return showDialog<PresetApplyMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('APPLY PRESET', style: AppTextStyles.screenTitle),
        content: Text(
          'How should "$presetName" be applied?',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PresetApplyMode.merge),
            child: const Text(
              'MERGE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PresetApplyMode.replace),
            child: const Text(
              'REPLACE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openProjectSettings() async {
    final project = _vm.currentProject;
    if (project == null || !_vm.canOpenProjectSettings) return;

    final result = await Navigator.of(context).push<ProjectDetailsResult>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
    if (!mounted) return;

    if (result == ProjectDetailsResult.deleted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (result == ProjectDetailsResult.updated) {
      final refreshed = await _vm.refreshCurrentProjectMetadata();
      if (!mounted || !refreshed) return;
      _showHistoryActionBar(
        message: 'Project updated: ${_vm.currentProject?.name ?? 'Project'}',
        icon: Icons.folder_open_outlined,
      );
    }
  }

  void _showVersionsSheet() {
    final scrollController = ScrollController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (sheetContext) => ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final versions = _vm.versions;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'VERSIONS',
                          style: TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.accent, size: 20),
                        tooltip: 'Save version',
                        onPressed: _vm.canUseVersions
                            ? () {
                                Navigator.of(sheetContext).pop();
                                unawaited(_handleSaveVersion());
                              }
                            : null,
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.muted, height: 1),
                  if (versions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'NO VERSIONS SAVED',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
                      ),
                    )
                  else
                    Flexible(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          itemCount: versions.length,
                          itemBuilder: (context, index) {
                            final version = versions[index];
                            final isActive = version.id == _vm.activeVersion?.id;
                            final canDelete = versions.length > 1;
                            return InkWell(
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                unawaited(_handleSwitchVersion(version.id));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Icon(
                                        isActive ? Icons.radio_button_checked : Icons.history,
                                        color: isActive ? AppColors.highlight : AppColors.accent,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            version.name.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isActive ? AppColors.highlight : AppColors.accent,
                                              fontSize: 11,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isActive
                                                ? 'ACTIVE - ${_formatVersionTimestamp(version.createdAt)}'
                                                : _formatVersionTimestamp(version.createdAt),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.muted, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 17),
                                          color: AppColors.accent,
                                          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Rename version',
                                          onPressed: () {
                                            Navigator.of(sheetContext).pop();
                                            unawaited(_handleRenameVersion(version));
                                          },
                                        ),
                                        if (canDelete)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            color: AppColors.accent,
                                            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                            padding: EdgeInsets.zero,
                                            tooltip: 'Delete version',
                                            onPressed: () {
                                              Navigator.of(sheetContext).pop();
                                              unawaited(_handleDeleteVersion(version));
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(scrollController.dispose);
  }

  Future<void> _handleSaveVersion() async {
    final name = await _showVersionNameDialog(
      initialName: _vm.defaultVersionName,
      title: 'SAVE VERSION',
    );
    if (name == null) return;

    final version = await _vm.saveCurrentVersion(name: name);
    if (!mounted || version == null) return;
    _showHistoryActionBar(
      message: 'Version saved: ${version.name}',
      icon: Icons.history,
    );
  }

  Future<void> _handleRenameVersion(EditorVersion version) async {
    final name = await _showVersionNameDialog(
      initialName: version.name,
      title: 'RENAME VERSION',
    );
    if (name == null) return;

    final renamed = await _vm.renameVersion(version.id, name);
    if (!mounted || renamed == null) return;
    _showHistoryActionBar(
      message: 'Version renamed: ${renamed.name}',
      icon: Icons.edit,
    );
  }

  Future<void> _handleDeleteVersion(EditorVersion version) async {
    final confirmed = await _showDeleteVersionDialog(version.name);
    if (!mounted || !confirmed) return;

    final deleted = await _vm.deleteVersion(version.id);
    if (!mounted || !deleted) return;
    _showHistoryActionBar(
      message: 'Version deleted: ${version.name}',
      icon: Icons.delete_outline,
    );
  }

  Future<void> _handleSwitchVersion(String versionId) async {
    final result = await _vm.switchToVersion(versionId);
    if (!mounted || result == null) return;
    _showHistoryActionBar(
      message: 'Switched to: ${result.label}',
      icon: Icons.history,
    );
  }

  Future<bool> _showDeleteVersionDialog(String versionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'DELETE VERSION',
          style: TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 3),
        ),
        content: Text(
          'Are you sure? This cannot be restored.\n\n$versionName',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<String?> _showVersionNameDialog({
    required String initialName,
    required String title,
  }) async {
    final initialValue = initialName.length > EditorViewModel.versionNameMaxLength
        ? initialName.substring(0, EditorViewModel.versionNameMaxLength)
        : initialName;
    final controller = TextEditingController(text: initialValue);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 3),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: EditorViewModel.versionNameMaxLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(EditorViewModel.versionNameMaxLength),
          ],
          style: const TextStyle(color: AppColors.accent),
          decoration: const InputDecoration(
            labelText: 'Version name',
            counterText: '',
            labelStyle: TextStyle(color: AppColors.muted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.muted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.highlight),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null) return null;
    final trimmed = name.trim();
    return trimmed.isEmpty ? initialValue : trimmed;
  }

  String _formatVersionTimestamp(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _openAiSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AiSettingsScreen(
          initialProfiles: _vm.aiProfiles,
          initialApiKeysByProfileId: _vm.aiProfileApiKeys,
          initialActiveProfileId: _vm.activeAiProfileId,
          availableProviders: _vm.availableProviders,
          modelsForProvider: _vm.modelsForProvider,
          onSave: _vm.updateAiSettings,
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('RESET', style: AppTextStyles.screenTitle),
        content: const Text(
          'Are you sure you want to start over? This will reset your progress.',
          style: TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'NO',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(_vm.resetEdits());
            },
            child: const Text(
              'YES',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 28,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.muted, width: 0.5),
          ),
          child: Icon(icon, color: AppColors.accent, size: 15),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Future<void> _handleUndo() async {
    final result = await _vm.undo();
    if (!mounted || result == null) return;
    _showHistoryActionBar(
      message: 'Undone: ${result.label}',
      icon: Icons.undo,
    );
  }

  Future<void> _handleRedo() async {
    final result = await _vm.redo();
    if (!mounted || result == null) return;
    _showHistoryActionBar(
      message: 'Redone: ${result.label}',
      icon: Icons.redo,
    );
  }

  void _showHistoryActionBar({
    required String message,
    required IconData icon,
  }) {
    _historyActionHideTimer?.cancel();
    _historyActionClearTimer?.cancel();

    setState(() {
      _historyActionMessage = message;
      _historyActionIcon = icon;
      _historyActionVisible = true;
    });

    _historyActionHideTimer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _historyActionVisible = false);

      _historyActionClearTimer = Timer(const Duration(milliseconds: 260), () {
        if (!mounted || _historyActionVisible) return;
        setState(() => _historyActionMessage = '');
      });
    });
  }

  Widget _buildEditor() {
    final processedImage = _vm.processedImage;
    final originalPreviewImage = _vm.originalPreviewImage;
    final canShowPreview =
        processedImage != null &&
        originalPreviewImage != null &&
        _vm.hasPreviewImages;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToolbarIconButton(
                icon: Icons.undo,
                enabled: _vm.canUndo && !_vm.isProcessing && !_vm.isWaitingForAi,
                onTap: () => unawaited(_handleUndo()),
              ),
              const SizedBox(width: 8),
              _buildToolbarIconButton(
                icon: Icons.redo,
                enabled: _vm.canRedo && !_vm.isProcessing && !_vm.isWaitingForAi,
                onTap: () => unawaited(_handleRedo()),
              ),
              const SizedBox(width: 8),
              _buildToolbarIconButton(
                icon: Icons.history,
                enabled: _vm.canUseVersions,
                onTap: _showVersionsSheet,
              ),
              const SizedBox(width: 8),
              _buildToolbarIconButton(
                icon: Icons.layers_outlined,
                enabled: _vm.canUsePresets,
                onTap: () => unawaited(_openPresets()),
              ),
              const SizedBox(width: 8),
              _buildToolbarIconButton(
                icon: Icons.restart_alt,
                enabled: true,
                onTap: _showResetDialog,
                tooltip: 'Reset edits',
              ),
              // Future debug toolbar action:
              // _buildToolbarIconButton(
              //   icon: Icons.terminal,
              //   enabled: true,
              //   onTap: _vm.printLogs,
              // ),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
              Positioned.fill(
                child: canShowPreview
                    ? ImageViewer(
                        image: processedImage,
                        originalImage: originalPreviewImage,
                        isLoading: _vm.isProcessing || _vm.isWaitingForAi,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.highlight,
                          strokeWidth: 1,
                        ),
                      ),
              ),
              if (_vm.hasPendingEdits)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PendingEditsBar(
                    onApply: _vm.applyPendingEdits,
                    onDiscard: _vm.discardPendingEdits,
                  ),
                ),
              if (_historyActionMessage.isNotEmpty && !_vm.hasPendingEdits)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: HistoryActionBar(
                    visible: _historyActionVisible,
                    icon: _historyActionIcon,
                    message: _historyActionMessage,
                  ),
                ),
              if (_savedBannerVisible)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _savedBannerOpaque ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.highlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SAVED TO GALLERY',
                          style: TextStyle(color: AppColors.bg, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ModeTabBar(
          currentMode: _vm.editorMode,
          onModeChanged: _vm.setEditorMode,
          hasPendingBasicEdits: _vm.pendingAiEditTypes.isNotEmpty,
          hasPendingColorEdits: _vm.pendingAiColorRanges.isNotEmpty,
          hasPendingGradingEdits: _vm.pendingAiGradingZones.isNotEmpty,
          pendingAiGradient: aiProviderGradient(_vm.pendingAiProviderId),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            //might have to tweak these values later on other devices
            height: _vm.editorMode == EditorMode.askAi
                ? (MediaQuery.of(context).size.height -
                        MediaQuery.of(context).viewInsets.bottom) *
                    0.38
                : 149,
            child: _vm.editorMode == EditorMode.askAi
                ? ChatPanel(vm: _vm)
                : Container(
                    color: AppColors.surface,
                    child: _vm.editorMode == EditorMode.basic
                        ? BasicEditPanel(vm: _vm)
                        : _vm.editorMode == EditorMode.selectiveColor
                            ? ColorEditPanel(vm: _vm)
                            : GradingEditPanel(vm: _vm),
                  ),
          ),
        ),
      ],
    );
  }
}
