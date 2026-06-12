import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/editor_project.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../editor/editor_screen.dart';
import '../presets/my_presets_screen.dart';
import '../projects/projects_screen.dart';
import '../shared/app_dialog.dart';
import '../shared/app_snack_bar.dart';

enum _DraftRecoveryAction {
  discard,
  continueEditing,
  saveAsProject,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    HomeViewModel? viewModel,
  }) : _viewModel = viewModel;

  final HomeViewModel? _viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  late final HomeViewModel _vm;
  late final bool _ownsViewModel;
  bool _draftDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget._viewModel == null;
    _vm = widget._viewModel ?? HomeViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForDraft());
      unawaited(_vm.loadHomeData());
    });
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _vm.dispose();
    }
    super.dispose();
  }

  Future<void> _checkForDraft({bool force = false}) async {
    await _vm.checkForRecoverableDraft(force: force);
    if (!mounted || _draftDialogVisible) return;

    final draft = _vm.recoverableDraft;
    if (draft == null) {
      _showErrorIfNeeded();
      return;
    }

    _draftDialogVisible = true;
    final action = await _showDraftRecoveryDialog(draft);
    _draftDialogVisible = false;
    if (!mounted || action == null) return;

    switch (action) {
      case _DraftRecoveryAction.discard:
        final confirmed = await _showDiscardDraftDialog();
        if (!mounted) return;
        if (!confirmed) {
          unawaited(_checkForDraft(force: true));
          return;
        }
        final discarded = await _vm.discardRecoverableDraft();
        if (!mounted) return;
        if (!discarded) _showErrorIfNeeded();
        unawaited(_checkForDraft(force: true));
        break;
      case _DraftRecoveryAction.continueEditing:
        final projectId = _vm.continueRecoverableDraft();
        if (projectId != null) {
          await _openProject(projectId);
        }
        break;
      case _DraftRecoveryAction.saveAsProject:
        final name = await _showProjectNameDialog(draft);
        if (!mounted) return;
        if (name == null) {
          unawaited(_checkForDraft(force: true));
          return;
        }
        final projectId = await _vm.saveRecoverableDraftAsProject(name);
        if (!mounted) return;
        if (projectId == null) {
          _showErrorIfNeeded();
          return;
        }
        await _openProject(projectId);
        break;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (!mounted || pickedFile == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(importImagePath: pickedFile.path),
      ),
    );
    if (!mounted) return;
    unawaited(_checkForDraft(force: true));
    unawaited(_vm.loadHomeData(force: true));
  }

  Future<void> _openProject(int projectId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(projectId: projectId),
      ),
    );
    if (!mounted) return;
    unawaited(_checkForDraft(force: true));
    unawaited(_vm.loadHomeData(force: true));
  }

  Future<void> _openProjects() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ProjectsScreen(),
      ),
    );
    if (!mounted) return;
    unawaited(_checkForDraft(force: true));
    unawaited(_vm.loadHomeData(force: true));
  }

  Future<void> _openPresets() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const MyPresetsScreen(
          useDefaultThumbnailSource: true,
        ),
      ),
    );
    if (!mounted) return;
    unawaited(_checkForDraft(force: true));
    unawaited(_vm.loadHomeData(force: true));
  }

  void _showErrorIfNeeded() {
    final message = _vm.errorMessage;
    if (message == null || !mounted) return;

    showAppSnackBar(context, message, isError: true);
    _vm.clearError();
  }

  Future<_DraftRecoveryAction?> _showDraftRecoveryDialog(
    EditorProject draft,
  ) {
    return showAppChoiceDialog<_DraftRecoveryAction>(
      context,
      title: 'UNSAVED PROJECT',
      message: 'You have an unsaved project.',
      cancelLabel: null,
      barrierDismissible: false,
      actions: const [
        AppDialogAction(
          'DISCARD',
          _DraftRecoveryAction.discard,
          color: MooditColors.textMuted,
        ),
        AppDialogAction('CONTINUE', _DraftRecoveryAction.continueEditing),
        AppDialogAction(
          'SAVE AS PROJECT',
          _DraftRecoveryAction.saveAsProject,
        ),
      ],
    );
  }

  Future<bool> _showDiscardDraftDialog() {
    return showAppConfirmDialog(
      context,
      title: 'DISCARD PROJECT',
      message: 'Are you sure? This is irreversible.',
      confirmLabel: 'YES',
      cancelLabel: 'NO',
      destructive: true,
    );
  }

  Future<String?> _showProjectNameDialog(EditorProject draft) async {
    final initialName = _vm.suggestedProjectNameForDraft(draft);
    final name = await showAppTextInputDialog(
      context,
      title: 'SAVE AS PROJECT',
      label: 'PROJECT NAME',
      initialValue: initialName,
    );
    if (name == null) return null;
    final trimmed = name.trim();
    return trimmed.isEmpty ? initialName : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final isLoading = _vm.isCheckingDraft || _vm.isBusy;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: MooditColors.pageBackground,
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 0,
                  right: 0,
                  width: 220,
                  height: 170,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 0.82,
                        colors: [
                          Color(0x42FFFFFF),
                          Color(0x20FFFFFF),
                          Color(0x08FFFFFF),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.28, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MooditDims.screenPadding,
                      18,
                      MooditDims.screenPadding,
                      28,
                    ),
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 24),
                      _ImportCard(onTap: isLoading ? null : _pickImage),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _CountCard(
                              label: 'PROJECTS',
                              subtitle: '${_vm.projectsCount} saved',
                              icon: Icons.folder_open_outlined,
                              onTap: isLoading
                                  ? null
                                  : () => unawaited(_openProjects()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _CountCard(
                              label: 'PRESETS',
                              subtitle: '${_vm.presetsCount} looks',
                              icon: Icons.layers_outlined,
                              onTap: isLoading
                                  ? null
                                  : () => unawaited(_openPresets()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _RecentSection(
                        projects: _vm.recentProjects,
                        onSeeAll: isLoading
                            ? null
                            : () => unawaited(_openProjects()),
                        onOpenProject: isLoading
                            ? null
                            : (id) => unawaited(_openProject(id)),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      minHeight: 1,
                      backgroundColor: Colors.transparent,
                      color: MooditColors.baseAccent,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: MooditType.wordmark,
            children: const [
              TextSpan(text: 'Mood'),
              TextSpan(
                text: 'it',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(color: MooditColors.baseAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('MOOD-DRIVEN PHOTO EDITING', style: MooditType.kicker),
      ],
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 272,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: MooditColors.hairlineStrong),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF19191E), Color(0xFF0D0D10)],
            ),
            boxShadow: MooditDims.softDrop,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                top: -74,
                right: -62,
                width: 188,
                height: 154,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 0.82,
                      colors: [
                        Color(0x32FFFFFF),
                        Color(0x12FFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.46, 1.0],
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.78,
                    colors: [
                      MooditColors.baseGlow,
                      MooditColors.baseGlowFaint,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.38, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF101013),
                      border: Border.all(
                        color: MooditColors.baseAccent,
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: MooditColors.baseGlow,
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Color(0x18FFFFFF),
                          blurRadius: 46,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: MooditColors.baseAccent,
                      size: 30,
                      shadows: [
                        Shadow(
                          color: Color(0x99FFFFFF),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    'IMPORT PHOTO',
                    style: MooditType.monoLabel.copyWith(letterSpacing: 3.2),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Start a new mood from camera or library',
                    style: MooditType.bodySecondary.copyWith(
                      color: MooditColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 116,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MooditColors.card,
            borderRadius: BorderRadius.circular(MooditDims.cardRadius),
            border: Border.all(color: MooditColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: MooditColors.textSecondary, size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MooditType.monoLabel.copyWith(letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: MooditType.bodySecondary.copyWith(
                      color: MooditColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({
    required this.projects,
    required this.onSeeAll,
    required this.onOpenProject,
  });

  final List<EditorProject> projects;
  final VoidCallback? onSeeAll;
  final void Function(int projectId)? onOpenProject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT', style: MooditType.sectionLabel),
            if (projects.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'ALL  ›',
                  style: MooditType.monoMeta.copyWith(
                    color: MooditColors.baseAccent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (projects.isEmpty)
          _RecentEmpty()
        else
          Row(
            children: [
              for (var i = 0; i < projects.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _RecentThumb(
                    project: projects[i],
                    onTap: onOpenProject == null
                        ? null
                        : () => onOpenProject!(projects[i].id),
                  ),
                ),
              ],
              for (var i = projects.length; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
      ],
    );
  }
}

class _RecentEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MooditColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(MooditDims.controlRadius),
        border: Border.all(color: MooditColors.hairline),
      ),
      child: Text(
        'NO PROJECTS YET',
        style: MooditType.monoMeta.copyWith(color: MooditColors.textOff),
      ),
    );
  }
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({required this.project, required this.onTap});

  final EditorProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final previewPath = project.previewImagePath;
    final hasPreview = previewPath != null &&
        previewPath.isNotEmpty &&
        File(previewPath).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: MooditColors.card,
            borderRadius: BorderRadius.circular(MooditDims.controlRadius),
            border: Border.all(color: MooditColors.hairline),
          ),
          child: hasPreview
              ? Image.file(
                  File(previewPath),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              : const Icon(
                  Icons.image_outlined,
                  color: MooditColors.textOff,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
