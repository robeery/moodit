import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/editor_preset.dart';
import '../../model/rgba_image_frame.dart';
import '../../services/preset_thumbnail_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodel/presets_viewmodel.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
      ),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preset renamed.'),
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 2),
      ),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preset deleted.'),
        backgroundColor: AppColors.surface,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _showNameDialog({
    required String title,
    required String initialName,
  }) async {
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
        title: Text(title, style: AppTextStyles.screenTitle),
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
    return name;
  }

  Future<bool> _showDeleteDialog(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('DELETE PRESET', style: AppTextStyles.screenTitle),
        content: Text(
          'Are you sure? This cannot be restored.\n\n$name',
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
            title: const Text('MY PRESETS', style: AppTextStyles.screenTitle),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              if (_vm.isEmpty)
                const Center(
                  child: Text(
                    "You don't have any presets yet",
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
                    itemCount: _vm.presets.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.muted,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final preset = _vm.presets[index];
                      return _PresetRow(
                        preset: preset,
                        thumbnailBytes: _vm.thumbnailFor(preset),
                        showThumbnail: widget.thumbnailSourceFrame != null ||
                            widget.useDefaultThumbnailSource,
                        onTap: widget.selectionMode
                            ? () => Navigator.of(context).pop(preset)
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
              if (_vm.isLoading || _vm.isBusy || _vm.isLoadingThumbnails)
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (showThumbnail)
              _PresetPreview(thumbnailBytes: thumbnailBytes)
            else
              const Icon(Icons.layers_outlined, color: AppColors.muted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                preset.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.highlight,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.accent,
              tooltip: 'Rename preset',
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: onRename,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 19),
              color: AppColors.accent,
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

class _PresetPreview extends StatelessWidget {
  const _PresetPreview({
    required this.thumbnailBytes,
  });

  final Uint8List? thumbnailBytes;

  @override
  Widget build(BuildContext context) {
    final bytes = thumbnailBytes;
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.muted, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
      ),
      child: bytes == null
          ? const Icon(
              Icons.image_outlined,
              color: AppColors.muted,
              size: 24,
            )
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
    );
  }
}
