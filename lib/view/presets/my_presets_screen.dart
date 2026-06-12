import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../model/editor_preset.dart';
import '../../model/rgba_image_frame.dart';
import '../../services/preset_thumbnail_service.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodel/presets_viewmodel.dart';
import '../shared/app_dialog.dart';
import '../shared/app_snack_bar.dart';
import '../shared/app_top_bar.dart';
import '../shared/thumbnail_tile.dart';

class MyPresetsScreen extends StatefulWidget {
  const MyPresetsScreen({
    super.key,
    this.selectionMode = false,
    this.thumbnailSourceFrame,
    this.useDefaultThumbnailSource = false,
    PresetsViewModel? viewModel,
  }) : _viewModel = viewModel;

  final bool selectionMode;
  final RgbaImageFrame? thumbnailSourceFrame;
  final bool useDefaultThumbnailSource;
  final PresetsViewModel? _viewModel;

  @override
  State<MyPresetsScreen> createState() => _MyPresetsScreenState();
}

class _MyPresetsScreenState extends State<MyPresetsScreen> {
  late final PresetsViewModel _vm;
  late final bool _ownsViewModel;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget._viewModel == null;
    final thumbnailService = const PresetThumbnailService();
    _vm = widget._viewModel ??
        PresetsViewModel(
          thumbnailSourceFrame: widget.thumbnailSourceFrame,
          thumbnailSourceLoader: widget.useDefaultThumbnailSource
              ? thumbnailService.loadDefaultSourceFrame
              : null,
          thumbnailService: thumbnailService,
        );
    _scrollController = ScrollController();
    unawaited(_vm.loadPresets());
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

  Future<void> _renamePreset(EditorPreset preset) async {
    final name = await _showNameDialog(
      title: 'RENAME PRESET',
      initialName: preset.name,
    );
    if (name == null) return;

    final renamed = await _vm.renamePreset(preset, name);
    if (!mounted) return;
    if (!renamed) {
      _showErrorIfNeeded();
      return;
    }

    showAppSnackBar(context, 'Preset renamed.');
  }

  Future<void> _deletePreset(EditorPreset preset) async {
    final confirmed = await _showDeleteDialog(preset.name);
    if (!confirmed) return;

    final deleted = await _vm.deletePreset(preset);
    if (!mounted) return;
    if (!deleted) {
      _showErrorIfNeeded();
      return;
    }

    showAppSnackBar(context, 'Preset deleted.');
  }

  Future<String?> _showNameDialog({
    required String title,
    required String initialName,
  }) {
    return showAppTextInputDialog(
      context,
      title: title,
      label: 'PRESET NAME',
      initialValue: initialName,
      maxLength: editorPresetNameMaxLength,
    );
  }

  Future<bool> _showDeleteDialog(String name) {
    return showAppConfirmDialog(
      context,
      title: 'DELETE PRESET',
      message: 'Are you sure? This cannot be restored.\n\n$name',
      confirmLabel: 'DELETE',
      destructive: true,
    );
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

        final showThumbnail = widget.thumbnailSourceFrame != null ||
            widget.useDefaultThumbnailSource;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: MooditColors.pageBackground,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AppTopBar(
                    title: 'MY PRESETS',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_vm.isEmpty)
                          Center(
                            child: Text(
                              'NO PRESETS YET',
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
                              itemCount: _vm.presets.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: MooditColors.hairline,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final preset = _vm.presets[index];
                                return _PresetRow(
                                  preset: preset,
                                  thumbnailBytes: _vm.thumbnailFor(preset),
                                  showThumbnail: showThumbnail,
                                  onTap: widget.selectionMode
                                      ? () =>
                                          Navigator.of(context).pop(preset)
                                      : null,
                                  onRename: _vm.isBusy
                                      ? null
                                      : () => unawaited(_renamePreset(preset)),
                                  onDelete: _vm.isBusy
                                      ? null
                                      : () => unawaited(_deletePreset(preset)),
                                );
                              },
                            ),
                          ),
                        if (_vm.isLoading ||
                            _vm.isBusy ||
                            _vm.isLoadingThumbnails)
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

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.thumbnailBytes,
    required this.showThumbnail,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final EditorPreset preset;
  final Uint8List? thumbnailBytes;
  final bool showThumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bytes = thumbnailBytes;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (showThumbnail)
              ThumbnailTile(
                image: bytes == null ? null : MemoryImage(bytes),
                fallbackIcon: Icons.layers_outlined,
              )
            else
              const ThumbnailTile(fallbackIcon: Icons.layers_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MooditType.monoLabel.copyWith(letterSpacing: 1.2),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: MooditColors.textSecondary,
              tooltip: 'Rename preset',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: onRename,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 19),
              color: MooditColors.textSecondary,
              tooltip: 'Delete preset',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
