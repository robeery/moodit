import 'package:flutter/material.dart';
import '../../../model/export_option.dart';
import '../../../model/export_settings.dart';
import '../../../theme/app_theme.dart';
import 'export_settings_dialog.dart';

class EditorDrawer extends StatelessWidget {
  final VoidCallback onOpenAiSettings;
  final VoidCallback onOpenProjectSettings;
  final VoidCallback onOpenPresets;
  final bool showProjectSettings;
  final bool canOpenProjectSettings;
  final bool canOpenPresets;
  final bool canSavePreset;
  final void Function(ExportOption) onExport;
  final ExportSettings exportSettings;
  final void Function(ExportSettings) onExportSettingsChanged;

  const EditorDrawer({
    super.key,
    required this.onOpenAiSettings,
    required this.onOpenProjectSettings,
    required this.onOpenPresets,
    required this.showProjectSettings,
    required this.canOpenProjectSettings,
    required this.canOpenPresets,
    required this.canSavePreset,
    required this.onExport,
    required this.exportSettings,
    required this.onExportSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'MENU',
                style: const TextStyle(
                  color: AppColors.highlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ),
            const Divider(color: AppColors.muted, height: 1),
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.accent, size: 20),
              title: const Text(
                'AI SETTINGS',
                style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 2),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onOpenAiSettings();
              },
            ),
            if (showProjectSettings)
              ListTile(
                leading: Icon(
                  Icons.folder_open_outlined,
                  color: canOpenProjectSettings
                      ? AppColors.accent
                      : AppColors.muted,
                  size: 20,
                ),
                title: Text(
                  'PROJECT SETTINGS',
                  style: TextStyle(
                    color: canOpenProjectSettings
                        ? AppColors.accent
                        : AppColors.muted,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                enabled: canOpenProjectSettings,
                onTap: canOpenProjectSettings
                    ? () {
                        Navigator.of(context).pop();
                        onOpenProjectSettings();
                      }
                    : null,
              ),
            ListTile(
              leading: Icon(
                Icons.tune_outlined,
                color: canOpenPresets ? AppColors.accent : AppColors.muted,
                size: 20,
              ),
              title: Text(
                'MY PRESETS',
                style: TextStyle(
                  color: canOpenPresets ? AppColors.accent : AppColors.muted,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              enabled: canOpenPresets,
              onTap: canOpenPresets
                  ? () {
                      Navigator.of(context).pop();
                      onOpenPresets();
                    }
                  : null,
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.save_outlined, color: AppColors.accent, size: 20),
                title: const Text(
                  'SAVE',
                  style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 2),
                ),
                iconColor: AppColors.muted,
                collapsedIconColor: AppColors.muted,
                children: [
                  for (final option in ExportOption.values)
                    Builder(
                      builder: (context) {
                        final enabled = option.implemented &&
                            (option != ExportOption.preset || canSavePreset);
                        return ListTile(
                      contentPadding: const EdgeInsets.only(left: 40),
                      leading: Icon(option.icon, color: enabled ? AppColors.accent : AppColors.muted, size: 18),
                      title: Text(
                        option.implemented
                            ? option.label.toUpperCase()
                            : '${option.label.toUpperCase()} (TBD)',
                        style: TextStyle(
                          color: enabled ? AppColors.accent : AppColors.muted,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      trailing: option == ExportOption.gallery
                          ? IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.muted, size: 16),
                              onPressed: () async {
                                final result = await showExportSettingsDialog(context, exportSettings);
                                if (result != null) onExportSettingsChanged(result);
                              },
                            )
                          : null,
                      enabled: enabled,
                      onTap: enabled
                          ? () {
                              Navigator.of(context).pop();
                              onExport(option);
                            }
                          : null,
                    );
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.muted, height: 1),
          ],
        ),
      ),
    );
  }
}
