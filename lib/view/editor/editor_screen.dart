import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/export_option.dart';
import '../../viewmodel/editor_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../settings/ai_settings_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/editor_drawer.dart';
import 'widgets/pending_edits_bar.dart';
import 'widgets/image_viewer.dart';
import 'widgets/tbd_dialog.dart';
import 'panels/basic_edit_panel.dart';
import 'panels/color_edit_panel.dart';
import 'panels/grading_edit_panel.dart';
import 'panels/chat_panel.dart';
import 'widgets/mode_tab_bar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorViewModel _vm = EditorViewModel();
  final ImagePicker _picker = ImagePicker();
  bool _savedBannerVisible = false;
  bool _savedBannerOpaque = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      _vm.loadImage(bytes);
    }
  }

  @override
  void dispose() {
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
            onPickImage: _pickImage,
            onOpenAiSettings: _openAiSettings,
            onExport: _handleExport,
            exportSettings: _vm.exportSettings,
            onExportSettingsChanged: _vm.updateExportSettings,
          ),
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
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
          body: !_vm.hasImage
              ? EmptyState(onPickImage: _pickImage)
              : _buildEditor(),
        );
      },
    );
  }

  Future<void> _handleExport(ExportOption option) async {
    if (!option.implemented) {
      showTbdDialog(context);
      return;
    }

    if (!_vm.hasImage) return;

    try {
      await _vm.exportToGallery();
      if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              _vm.resetEdits();
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

  Widget _buildToolbarButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.muted, width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToolbarButton('RESET', _showResetDialog),
              const SizedBox(width: 12),
              _buildToolbarButton('LOGS', _vm.printLogs),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
              Positioned.fill(
                child: ImageViewer(
                  imageBytes: _vm.processedImage!,
                  originalBytes: _vm.originalBytes!,
                  isLoading: _vm.isProcessing || _vm.isWaitingForAi,
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
