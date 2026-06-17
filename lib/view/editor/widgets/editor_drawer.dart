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
      backgroundColor: MooditColors.cardAlt,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text('MENU', style: MooditType.screenTitle),
            ),
            const Divider(color: MooditColors.hairline, height: 1),
            _DrawerTile(
              icon: Icons.tune,
              label: 'AI SETTINGS',
              onTap: () {
                Navigator.of(context).pop();
                onOpenAiSettings();
              },
            ),
            if (showProjectSettings)
              _DrawerTile(
                icon: Icons.folder_open_outlined,
                label: 'PROJECT SETTINGS',
                enabled: canOpenProjectSettings,
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenProjectSettings();
                },
              ),
            _DrawerTile(
              icon: Icons.layers_outlined,
              label: 'MY PRESETS',
              enabled: canOpenPresets,
              onTap: () {
                Navigator.of(context).pop();
                onOpenPresets();
              },
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.save_outlined,
                  color: MooditColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  'SAVE',
                  style: MooditType.monoLabel.copyWith(letterSpacing: 2),
                ),
                iconColor: MooditColors.textMuted,
                collapsedIconColor: MooditColors.textMuted,
                children: [
                  for (final option in ExportOption.values)
                    Builder(
                      builder: (context) {
                        final enabled = option.implemented &&
                            (option != ExportOption.preset || canSavePreset);
                        final color = enabled
                            ? MooditColors.textSecondary
                            : MooditColors.textOff;
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 40),
                          leading: Icon(option.icon, color: color, size: 18),
                          title: Text(
                            option.implemented
                                ? option.label.toUpperCase()
                                : '${option.label.toUpperCase()} (TBD)',
                            style: MooditType.monoMeta.copyWith(color: color),
                          ),
                          trailing: option == ExportOption.gallery
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: MooditColors.textMuted,
                                    size: 16,
                                  ),
                                  onPressed: () async {
                                    final result = await showExportSettingsDialog(
                                        context, exportSettings);
                                    if (result != null) {
                                      onExportSettingsChanged(result);
                                    }
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
            const Divider(color: MooditColors.hairline, height: 1),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? MooditColors.textSecondary : MooditColors.textOff;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: MooditType.monoMeta.copyWith(color: color)),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
