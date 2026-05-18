import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../model/editor_project.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/project_details_viewmodel.dart';

enum ProjectDetailsResult {
  deleted,
  updated,
}

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
    ProjectDetailsViewModel? viewModel,
  }) : _viewModel = viewModel;

  final int projectId;
  final ProjectDetailsViewModel? _viewModel;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late final ProjectDetailsViewModel _vm;
  late final bool _ownsViewModel;
  late final ScrollController _scrollController;
  bool _hasUpdatedProject = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget._viewModel == null;
    _vm = widget._viewModel ??
        ProjectDetailsViewModel(projectId: widget.projectId);
    _scrollController = ScrollController();
    unawaited(_vm.loadProject());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsViewModel) {
      _vm.dispose();
    }
    super.dispose();
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

  Future<void> _renameProject() async {
    final project = _vm.project;
    if (project == null) return;

    final name = await _showProjectNameDialog(displayProjectName(project));
    if (!mounted || name == null) return;

    final renamed = await _vm.renameProject(name);
    if (!mounted || !renamed) return;

    _hasUpdatedProject = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Project renamed: ${_vm.project?.name ?? name.trim()}'),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteProject() async {
    final confirmed = await _showDeleteProjectDialog();
    if (!mounted || !confirmed) return;

    final deleted = await _vm.deleteProject();
    if (!mounted || !deleted) return;

    Navigator.of(context).pop(ProjectDetailsResult.deleted);
  }

  Future<String?> _showProjectNameDialog(String initialName) async {
    final controller = TextEditingController(text: initialName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: const Text(
          'RENAME PROJECT',
          style: AppTextStyles.screenTitle,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: ProjectDetailsViewModel.projectNameMaxLength,
          style: const TextStyle(color: AppColors.highlight),
          decoration: const InputDecoration(
            counterStyle: TextStyle(color: AppColors.muted),
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
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.highlight,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
  }

  Future<bool> _showDeleteProjectDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: const Text(
              'DELETE PROJECT',
              style: AppTextStyles.screenTitle,
            ),
            content: const Text(
              'Delete project? This removes the project, versions, history, '
              'and app-owned image files. This cannot be restored.',
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
                    color: AppColors.highlight,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleBack() {
    Navigator.of(context).pop(
      _hasUpdatedProject ? ProjectDetailsResult.updated : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorIfNeeded();
            });
          }

          final project = _vm.project;
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              iconTheme: const IconThemeData(color: AppColors.highlight),
              title: const Text(
                'PROJECT DETAILS',
                style: AppTextStyles.screenTitle,
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBack,
              ),
            ),
            body: Stack(
              children: [
                if (project == null && !_vm.isLoading)
                  const Center(
                    child: Text(
                      'PROJECT NOT FOUND',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                else if (project != null)
                  Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 3,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 20, 28),
                      children: [
                        _ProjectHeader(project: project),
                        const SizedBox(height: 24),
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'RENAME PROJECT',
                          enabled: !_vm.isBusy,
                          onTap: _renameProject,
                        ),
                        const Divider(color: AppColors.muted, height: 1),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          label: 'DELETE PROJECT',
                          enabled: !_vm.isBusy,
                          onTap: _deleteProject,
                        ),
                        const SizedBox(height: 26),
                        const _SectionTitle('PROJECT INFO'),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'STATUS',
                          value: project.status.storageValue.toUpperCase(),
                        ),
                        _InfoRow(
                          label: 'VERSIONS',
                          value: _vm.versionCount.toString(),
                        ),
                        _InfoRow(
                          label: 'CREATED',
                          value: _formatDate(project.createdAt),
                        ),
                        _InfoRow(
                          label: 'LAST UPDATED',
                          value: _formatDate(project.updatedAt),
                        ),
                        _InfoRow(
                          label: 'LAST ACCESSED',
                          value: _formatNullableDate(project.lastOpenedAt),
                        ),
                        _InfoRow(
                          label: 'ORIGINAL SIZE',
                          value:
                              '${project.originalWidth} x ${project.originalHeight}',
                        ),
                        _InfoRow(
                          label: 'PREVIEW SIZE',
                          value:
                              '${project.previewWidth} x ${project.previewHeight}',
                        ),
                        _InfoRow(
                          label: 'ORIGINAL PATH',
                          value: project.originalImagePath,
                          allowWrap: true,
                        ),
                      ],
                    ),
                  ),
                if (_vm.isLoading || _vm.isBusy)
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _formatNullableDate(DateTime? date) {
    if (date == null) return 'NEVER';
    return _formatDate(date);
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
  });

  final EditorProject project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProjectPreview(path: project.previewImagePath),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            displayProjectName(project).toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.highlight,
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({
    required this.path,
  });

  final String? path;

  @override
  Widget build(BuildContext context) {
    final previewPath = path;
    final hasPreview =
        previewPath != null &&
        previewPath.isNotEmpty &&
        File(previewPath).existsSync();

    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.muted, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: hasPreview
          ? Image.file(
              File(previewPath),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : const Icon(
              Icons.image_outlined,
              color: AppColors.muted,
              size: 26,
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.highlight : AppColors.muted;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.highlight,
        fontSize: 12,
        letterSpacing: 3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.allowWrap = false,
  });

  final String label;
  final String value;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            allowWrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: allowWrap ? 4 : 1,
              overflow: allowWrap ? TextOverflow.ellipsis : TextOverflow.fade,
              softWrap: allowWrap,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
