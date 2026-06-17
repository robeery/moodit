import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/editor_project.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/project_details_viewmodel.dart';
import '../shared/app_dialog.dart';
import '../shared/app_snack_bar.dart';
import '../shared/app_top_bar.dart';
import '../shared/thumbnail_tile.dart';

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

    showAppSnackBar(context, message, isError: true);
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
    showAppSnackBar(
      context,
      'Project renamed: ${_vm.project?.name ?? name.trim()}',
    );
  }

  Future<void> _deleteProject() async {
    final confirmed = await _showDeleteProjectDialog();
    if (!mounted || !confirmed) return;

    final deleted = await _vm.deleteProject();
    if (!mounted || !deleted) return;

    Navigator.of(context).pop(ProjectDetailsResult.deleted);
  }

  Future<String?> _showProjectNameDialog(String initialName) {
    return showAppTextInputDialog(
      context,
      title: 'RENAME PROJECT',
      initialValue: initialName,
      maxLength: ProjectDetailsViewModel.projectNameMaxLength,
    );
  }

  Future<bool> _showDeleteProjectDialog() {
    return showAppConfirmDialog(
      context,
      title: 'DELETE PROJECT',
      message: 'Delete project? This removes the project, versions, history, '
          'and app-owned image files. This cannot be restored.',
      confirmLabel: 'DELETE',
      destructive: true,
    );
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
            body: Container(
              decoration: const BoxDecoration(
                gradient: MooditColors.pageBackground,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    AppTopBar(
                      title: 'PROJECT DETAILS',
                      onBack: _handleBack,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          if (project == null && !_vm.isLoading)
                            Center(
                              child: Text(
                                'PROJECT NOT FOUND',
                                style: MooditType.monoMeta.copyWith(
                                  color: MooditColors.textOff,
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
                                padding: const EdgeInsets.fromLTRB(
                                  MooditDims.screenPadding,
                                  10,
                                  MooditDims.screenPadding,
                                  28,
                                ),
                                children: [
                                  _ProjectHeader(
                                    project: project,
                                    versionCount: _vm.versionCount,
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DetailButton(
                                          icon: Icons.edit_outlined,
                                          label: 'RENAME',
                                          enabled: !_vm.isBusy,
                                          onTap: _renameProject,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _DetailButton(
                                          icon: Icons.delete_outline,
                                          label: 'DELETE',
                                          color: MooditColors.destructive,
                                          enabled: !_vm.isBusy,
                                          onTap: _deleteProject,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    'PROJECT INFO',
                                    style: MooditType.sectionLabel,
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoCard(
                                    rows: [
                                      _InfoRow(
                                        label: 'STATUS',
                                        value: project.status.storageValue
                                            .toUpperCase(),
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
                                        label: 'ORIGINAL SIZE',
                                        value:
                                            '${project.originalWidth} x ${project.originalHeight}',
                                      ),
                                      _InfoRow(
                                        label: 'PREVIEW SIZE',
                                        value:
                                            '${project.previewWidth} x ${project.previewHeight}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (_vm.isLoading || _vm.isBusy)
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
                  ],
                ),
              ),
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

}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
    required this.versionCount,
  });

  final EditorProject project;
  final int versionCount;

  @override
  Widget build(BuildContext context) {
    final isDraft = project.status == EditorProjectStatus.draft;
    final statusLabel = isDraft ? 'DRAFT' : 'SAVED';
    final versionLabel = versionCount == 1 ? 'VERSION' : 'VERSIONS';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThumbnailTile(
          image: fileThumbnailProvider(project.previewImagePath),
          size: 84,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                displayProjectName(project),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MooditType.displayTitle,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: MooditColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(MooditDims.pillRadius),
                  border: Border.all(color: MooditColors.hairline),
                ),
                child: Text(
                  '$statusLabel  ·  $versionCount $versionLabel',
                  style: MooditType.monoMeta.copyWith(
                    color: MooditColors.baseAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _DetailButton extends StatelessWidget {
  const _DetailButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color = MooditColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tint = enabled ? color : MooditColors.textOff;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(MooditDims.controlRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MooditColors.card,
          borderRadius: BorderRadius.circular(MooditDims.controlRadius),
          border: Border.all(
            color: color == MooditColors.destructive
                ? MooditColors.destructive.withValues(alpha: 0.4)
                : MooditColors.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tint, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: MooditType.monoLabel.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MooditColors.card,
        borderRadius: BorderRadius.circular(MooditDims.cardRadius),
        border: Border.all(color: MooditColors.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(color: MooditColors.hairline, height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 122,
            child: Text(label, style: MooditType.monoMeta),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.right,
              style: MooditType.bodySecondary.copyWith(
                color: MooditColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
