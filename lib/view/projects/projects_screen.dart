import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../model/editor_project.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/projects_viewmodel.dart';
import '../editor/editor_screen.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project deleted.'),
          backgroundColor: AppColors.surface,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: AppColors.highlight),
            title: const Text('MY PROJECTS', style: AppTextStyles.screenTitle),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              if (_vm.isEmpty)
                const Center(
                  child: Text(
                    "You don't have any projects yet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      letterSpacing: 2,
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 20, 24),
                    itemCount: _vm.projects.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.muted,
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
            _ProjectPreview(path: project.previewImagePath),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.highlight,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'LAST UPDATED ${_formatProjectDate(project.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              color: AppColors.muted,
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
      width: 64,
      height: 64,
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
              size: 24,
            ),
    );
  }
}
