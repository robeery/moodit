import 'dart:async';

import 'package:flutter/material.dart';

import '../../model/editor_project.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodel/projects_viewmodel.dart';
import '../editor/editor_screen.dart';
import '../shared/app_snack_bar.dart';
import '../shared/app_top_bar.dart';
import '../shared/thumbnail_tile.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    ProjectsViewModel? viewModel,
  }) : _viewModel = viewModel;

  final ProjectsViewModel? _viewModel;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final ProjectsViewModel _vm;
  late final bool _ownsViewModel;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget._viewModel == null;
    _vm = widget._viewModel ?? ProjectsViewModel();
    _scrollController = ScrollController();
    unawaited(_vm.loadProjects());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_ownsViewModel) {
      _vm.dispose();
    }
    super.dispose();
  }

  Future<void> _openProject(EditorProject project) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(projectId: project.id),
      ),
    );
    if (!mounted) return;
    unawaited(_vm.refresh());
  }

  Future<void> _openProjectDetails(EditorProject project) async {
    final result = await Navigator.of(context).push<ProjectDetailsResult>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
    if (!mounted) return;

    unawaited(_vm.refresh());
    if (result == ProjectDetailsResult.deleted) {
      showAppSnackBar(context, 'Project deleted.');
    }
  }

  void _showErrorIfNeeded() {
    final message = _vm.errorMessage;
    if (message == null || !mounted) return;

    showAppSnackBar(context, message, isError: true);
    _vm.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (_vm.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorIfNeeded();
          });
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
                    title: 'MY PROJECTS',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_vm.isEmpty)
                          Center(
                            child: Text(
                              'NO PROJECTS YET',
                              style: MooditType.monoMeta.copyWith(
                                color: MooditColors.textOff,
                              ),
                            ),
                          )
                        else
                          Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            radius: const Radius.circular(8),
                            thickness: 3,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                MooditDims.screenPadding,
                                8,
                                MooditDims.screenPadding,
                                24,
                              ),
                              itemCount: _vm.projects.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: MooditColors.hairline,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final project = _vm.projects[index];
                                return _ProjectRow(
                                  project: project,
                                  onTap: () => unawaited(_openProject(project)),
                                  onDetailsTap: () =>
                                      unawaited(_openProjectDetails(project)),
                                );
                              },
                            ),
                          ),
                        if (_vm.isLoading)
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
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.onTap,
    required this.onDetailsTap,
  });

  final EditorProject project;
  final VoidCallback onTap;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ThumbnailTile(
              image: fileThumbnailProvider(project.previewImagePath),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProjectName(project),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MooditType.monoLabel.copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'UPDATED ${_formatProjectDate(project.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MooditType.monoMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              color: MooditColors.textSecondary,
              tooltip: 'Project details',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: onDetailsTap,
            ),
          ],
        ),
      ),
    );
  }

  String _formatProjectDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
