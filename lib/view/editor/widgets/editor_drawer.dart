import 'package:flutter/material.dart';
import '../../../model/export_option.dart';
import '../../../model/export_settings.dart';
import '../../../theme/app_theme.dart';
import 'export_settings_dialog.dart';

class EditorDrawer extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onOpenAiSettings;
  final void Function(ExportOption) onExport;
  final ExportSettings exportSettings;
  final void Function(ExportSettings) onExportSettingsChanged;

  const EditorDrawer({
    super.key,
    required this.onPickImage,
    required this.onOpenAiSettings,
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
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accent, size: 20),
              title: const Text(
                'OPEN NEW PICTURE',
                style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 2),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onPickImage();
              },
            ),
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
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 40),
                      leading: Icon(option.icon, color: option.implemented ? AppColors.accent : AppColors.muted, size: 18),
                      title: Text(
                        option.implemented
                            ? option.label.toUpperCase()
                            : '${option.label.toUpperCase()} (TBD)',
                        style: TextStyle(
                          color: option.implemented ? AppColors.accent : AppColors.muted,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      trailing: option.implemented
                          ? IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.muted, size: 16),
                              onPressed: () async {
                                final result = await showExportSettingsDialog(context, exportSettings);
                                if (result != null) onExportSettingsChanged(result);
                              },
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        onExport(option);
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
