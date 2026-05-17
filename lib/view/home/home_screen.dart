import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/editor_project.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../editor/editor_screen.dart';
import '../editor/widgets/tbd_dialog.dart';

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
  }

  Future<void> _openProject(int projectId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(projectId: projectId),
      ),
    );
    if (!mounted) return;
    unawaited(_checkForDraft(force: true));
  }

  void _showErrorIfNeeded() {
    final message = _vm.errorMessage;
    if (message == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      ),
    );
    _vm.clearError();
  }

  Future<_DraftRecoveryAction?> _showDraftRecoveryDialog(
    EditorProject draft,
  ) {
    return showDialog<_DraftRecoveryAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'UNSAVED PROJECT',
          style: TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 3),
        ),
        content: Text(
          'You have an unsaved project.\n',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_DraftRecoveryAction.discard),
            child: const Text(
              'DISCARD',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_DraftRecoveryAction.continueEditing),
            child: const Text(
              'CONTINUE',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_DraftRecoveryAction.saveAsProject),
            child: const Text(
              'SAVE AS PROJECT',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDiscardDraftDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'DISCARD PROJECT',
          style: TextStyle(color: AppColors.highlight, fontSize: 12, letterSpacing: 3),
        ),
        content: const Text(
          'Are you sure? This is irreversible.',
          style: TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'NO',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'YES',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<String?> _showProjectNameDialog(EditorProject draft) async {
    final initialName = draft.name.trim().isEmpty
        ? 'Project ${draft.id}'
        : draft.name.trim();
    final controller = TextEditingController(text: initialName);
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
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            title: const Text('MOOD EDIT', style: AppTextStyles.screenTitle),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
	                  child: LayoutBuilder(
	                    builder: (context, constraints) {
	                      final tileSize = constraints.maxWidth
	                          .clamp(132.0, 160.0)
	                          .toDouble();
	                      return Column(
	                        mainAxisSize: MainAxisSize.min,
	                        children: [
	                          _HomeActionTile(
	                            icon: Icons.add,
                            label: 'IMPORT PHOTO',
	                            size: tileSize,
	                            onPressed: isLoading ? null : _pickImage,
	                          ),
	                          const SizedBox(height: 16),
	                          _HomeActionTile(
	                            icon: Icons.folder_open_outlined,
	                            label: 'MY PROJECTS',
                            size: tileSize,
                            onPressed: isLoading ? null : () => showTbdDialog(context),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (isLoading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    minHeight: 1,
                    backgroundColor: AppColors.surface,
                    color: AppColors.highlight,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.label,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.muted, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.muted, size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: content,
      ),
    );
  }
}
