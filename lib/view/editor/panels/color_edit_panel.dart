import 'package:flutter/material.dart';
import '../../../model/color_edit.dart';
import '../../../theme/ai_provider_theme.dart';
import '../../../theme/color_swatches.dart';
import '../../../theme/slider_theme.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';
import '../widgets/gradient_slider_row.dart';

class ColorEditPanel extends StatelessWidget {
  final EditorViewModel vm;

  const ColorEditPanel({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSliders(),
        _buildColorBar(),
      ],
    );
  }

  Widget _buildSliders() {
    final colorEdit = vm.getColorEdit(vm.selectedColorRange);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          GradientSliderRow(
            label: 'HUE',
            value: colorEdit.hue,
            min: -100,
            max: 100,
            valueText: colorEdit.hue.toStringAsFixed(0),
            gradient: hueGradientColors(vm.selectedColorRange),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) => vm.updateColorEditPreview(colorEdit.copyWith(hue: v)),
            onChangeEnd: (v) => vm.applyColorEdit(colorEdit.copyWith(hue: v)),
          ),
          GradientSliderRow(
            label: 'SAT',
            value: colorEdit.saturation,
            min: -100,
            max: 100,
            valueText: colorEdit.saturation.toStringAsFixed(0),
            gradient: saturationGradientColors(vm.selectedColorRange),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) =>
                vm.updateColorEditPreview(colorEdit.copyWith(saturation: v)),
            onChangeEnd: (v) =>
                vm.applyColorEdit(colorEdit.copyWith(saturation: v)),
          ),
          GradientSliderRow(
            label: 'LUM',
            value: colorEdit.luminance,
            min: -100,
            max: 100,
            valueText: colorEdit.luminance.toStringAsFixed(0),
            gradient: luminanceGradientColors(vm.selectedColorRange),
            onChangeStart: vm.beginManualEdit,
            onChanged: (v) =>
                vm.updateColorEditPreview(colorEdit.copyWith(luminance: v)),
            onChangeEnd: (v) =>
                vm.applyColorEdit(colorEdit.copyWith(luminance: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBar() {
    final pendingAiGradient = aiProviderGradient(vm.pendingAiProviderId);

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: ColorRange.values.map((range) {
            final isSelected = range == vm.selectedColorRange;
            final hasEdit = vm.hasColorEdit(range);
            final isPendingAiEdit = vm.hasPendingEdits && vm.pendingAiColorRanges.contains(range);
            final showIndicator = hasEdit || isPendingAiEdit;
            final color = SelectiveColorSwatches.colorRange[range]!;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => vm.setSelectedColorRange(range),
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? MooditColors.baseAccent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedOpacity(
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
                                  : MooditColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
