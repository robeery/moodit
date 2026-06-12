import 'package:flutter/material.dart';
import '../../../model/export_settings.dart';
import '../../../theme/app_tokens.dart';

Future<ExportSettings?> showExportSettingsDialog(
  BuildContext context,
  ExportSettings current,
) {
  return showDialog<ExportSettings>(
    context: context,
    builder: (ctx) => _ExportSettingsDialog(settings: current),
  );
}

class _ExportSettingsDialog extends StatefulWidget {
  final ExportSettings settings;
  const _ExportSettingsDialog({required this.settings});

  @override
  State<_ExportSettingsDialog> createState() => _ExportSettingsDialogState();
}

class _ExportSettingsDialogState extends State<_ExportSettingsDialog> {
  late ImageFormat _format;
  late int _quality;

  @override
  void initState() {
    super.initState();
    _format = widget.settings.format;
    _quality = widget.settings.quality;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MooditColors.cardAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MooditDims.cardRadius),
      ),
      title: Text('EXPORT SETTINGS', style: MooditType.screenTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FORMAT', style: MooditType.sectionLabel),
          const SizedBox(height: 8),
          Row(
            children: ImageFormat.values.map((f) {
              final selected = f == _format;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _format = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? MooditColors.baseAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(MooditDims.controlRadius),
                      border: Border.all(
                        color: selected
                            ? MooditColors.baseAccent
                            : MooditColors.hairlineStrong,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: MooditType.monoLabel.copyWith(
                        color: selected
                            ? MooditColors.bgInner
                            : MooditColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_format != ImageFormat.png) ...[
            const SizedBox(height: 20),
            Text('QUALITY  $_quality%', style: MooditType.sectionLabel),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: MooditColors.baseAccent,
                inactiveTrackColor: MooditColors.hairlineStrong,
                thumbColor: MooditColors.baseAccent,
                overlayColor: MooditColors.baseGlow,
                trackHeight: 2,
              ),
              child: Slider(
                value: _quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                onChanged: (v) => setState(() => _quality = v.round()),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: MooditType.monoMeta.copyWith(color: MooditColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ExportSettings(format: _format, quality: _quality),
          ),
          child: Text(
            'SAVE',
            style: MooditType.monoMeta.copyWith(color: MooditColors.baseAccent),
          ),
        ),
      ],
    );
  }
}
