import 'package:flutter/material.dart';
import '../../../model/color_grading_edit.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';

class GradingEditPanel extends StatelessWidget {
  final EditorViewModel vm;

  const GradingEditPanel({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSliders(context),
        _buildZoneBar(),
      ],
    );
  }

  Widget _buildSliders(BuildContext context) {
    final edit = vm.getColorGradingEdit(vm.selectedGradingZone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _buildSliderRow(context, 'HUE', edit.hue, 0, 360, '${edit.hue.toStringAsFixed(0)}°',
            (v) => vm.applyColorGradingEdit(edit.copyWith(hue: v)),
            (v) => vm.updateColorGradingEditPreview(edit.copyWith(hue: v)),
            gradient: gradingHueGradientColors(),
          ),
          _buildSliderRow(context, 'SAT', edit.strength, 0, 100, '${edit.strength.toStringAsFixed(0)}%',
            (v) => vm.applyColorGradingEdit(edit.copyWith(strength: v)),
            (v) => vm.updateColorGradingEditPreview(edit.copyWith(strength: v)),
            gradient: gradingStrengthGradientColors(edit.hue),
          ),
          _buildSliderRow(context, 'LUM', edit.luminance, -100, 100, edit.luminance.toStringAsFixed(0),
            (v) => vm.applyColorGradingEdit(edit.copyWith(luminance: v)),
            (v) => vm.updateColorGradingEditPreview(edit.copyWith(luminance: v)),
            gradient: gradingLuminanceGradientColors(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(BuildContext context, String label, double value,
      double min, double max, String display,
      Function(double) onChangeEnd, Function(double) onChanged,
      {List<Color>? gradient}) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: AppTextStyles.mutedSmall),
        ),
        Expanded(
          child: gradient != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: LinearGradient(colors: gradient),
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: AppSliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        min: min,
                        max: max,
                        value: value,
                        onChanged: onChanged,
                        onChangeEnd: onChangeEnd,
                      ),
                    ),
                  ],
                )
              : SliderTheme(
                  data: AppSliderTheme.of(context),
                  child: Slider(
                    min: min,
                    max: max,
                    value: value,
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                  ),
                ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.highlight,
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneBar() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: ColorGradingZone.values.length,
        itemBuilder: (context, index) {
          final zone = ColorGradingZone.values[index];
          final isSelected = zone == vm.selectedGradingZone;
          final hasEdit = vm.hasColorGradingEdit(zone);
          final isPendingAiEdit = vm.hasPendingEdits && vm.pendingAiGradingZones.contains(zone);

          return GestureDetector(
            onTap: () => vm.setSelectedGradingZone(zone),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.highlight : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isSelected ? AppColors.highlight : AppColors.muted,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    zone.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.bg : AppColors.muted,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasEdit) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isPendingAiEdit
                            ? const LinearGradient(
                                colors: [Color(0xFF1FBC9C), Color(0xFF647EFF)],
                              )
                            : null,
                        color: isPendingAiEdit
                            ? null
                            : (isSelected ? AppColors.bg : AppColors.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
