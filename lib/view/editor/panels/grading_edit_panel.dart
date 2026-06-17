import 'package:flutter/material.dart';
import '../../../model/color_grading_edit.dart';
import '../../../theme/ai_provider_theme.dart';
import '../../../theme/slider_theme.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';
import '../widgets/gradient_slider_row.dart';

class GradingEditPanel extends StatelessWidget {
  final EditorViewModel vm;

  const GradingEditPanel({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSliders(),
        _buildZoneBar(),
      ],
    );
  }

  Widget _buildSliders() {
    final edit = vm.getColorGradingEdit(vm.selectedGradingZone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          GradientSliderRow(
            label: 'HUE',
            value: edit.hue,
            min: 0,
            max: 360,
            valueText: '${edit.hue.toStringAsFixed(0)}°',
            valueWidth: 40,
            gradient: gradingHueGradientColors(),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) =>
                vm.updateColorGradingEditPreview(edit.copyWith(hue: v)),
            onChangeEnd: (v) => vm.applyColorGradingEdit(edit.copyWith(hue: v)),
          ),
          GradientSliderRow(
            label: 'SAT',
            value: edit.strength,
            min: 0,
            max: 100,
            valueText: '${edit.strength.toStringAsFixed(0)}%',
            valueWidth: 40,
            gradient: gradingStrengthGradientColors(edit.hue),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) =>
                vm.updateColorGradingEditPreview(edit.copyWith(strength: v)),
            onChangeEnd: (v) =>
                vm.applyColorGradingEdit(edit.copyWith(strength: v)),
          ),
          GradientSliderRow(
            label: 'LUM',
            value: edit.luminance,
            min: -100,
            max: 100,
            valueText: edit.luminance.toStringAsFixed(0),
            valueWidth: 40,
            gradient: gradingLuminanceGradientColors(),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) =>
                vm.updateColorGradingEditPreview(edit.copyWith(luminance: v)),
            onChangeEnd: (v) =>
                vm.applyColorGradingEdit(edit.copyWith(luminance: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneBar() {
    final pendingAiGradient = aiProviderGradient(vm.pendingAiProviderId);

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
          final showIndicator = hasEdit || isPendingAiEdit;

          return GestureDetector(
            onTap: () => vm.setSelectedGradingZone(zone),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? MooditColors.baseAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(MooditDims.pillRadius),
                border: Border.all(
                  color: isSelected
                      ? MooditColors.baseAccent
                      : MooditColors.hairlineStrong,
                  width: 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Text(
                    zone.name.toUpperCase(),
                    style: MooditType.monoLabel.copyWith(
                      color: isSelected
                          ? MooditColors.bgInner
                          : MooditColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: showIndicator ? 1 : 0,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isPendingAiEdit
                                ? pendingAiGradient
                                : null,
                            color: isPendingAiEdit
                                ? null
                                : (isSelected
                                    ? MooditColors.bgInner
                                    : MooditColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
