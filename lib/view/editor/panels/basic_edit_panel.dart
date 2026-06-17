import 'package:flutter/material.dart';
import '../../../model/edit.dart';
import '../../../theme/ai_provider_theme.dart';
import '../../../theme/slider_theme.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';

class BasicEditPanel extends StatefulWidget {
  final EditorViewModel vm;

  const BasicEditPanel({super.key, required this.vm});

  @override
  State<BasicEditPanel> createState() => _BasicEditPanelState();
}

class _BasicEditPanelState extends State<BasicEditPanel> {
  final _scrollController = ScrollController();

  EditorViewModel get vm => widget.vm;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const Map<OperationType, IconData> _operationIcons = {
    OperationType.exposure: Icons.exposure,
    OperationType.brightness: Icons.wb_sunny_outlined,
    OperationType.highlights: Icons.tonality,
    OperationType.shadows: Icons.tonality,
    OperationType.contrast: Icons.contrast,
    OperationType.warmth: Icons.thermostat,
    OperationType.tint: Icons.water_drop_outlined,
    OperationType.sharpness: Icons.change_history,
    OperationType.saturation: Icons.invert_colors,
    OperationType.definition: Icons.details,
    OperationType.vibrance: Icons.invert_colors,
    OperationType.blackpoint: Icons.album,
    OperationType.vignette: Icons.vignette,
    OperationType.blur: Icons.blur_linear_sharp,
    OperationType.grain: Icons.grain_sharp,
    OperationType.fade: Icons.deblur,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSlider(context),
        _buildOperationBar(),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    final currentValue = vm.getEditValue(vm.selectedOperation);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vm.selectedOperation.name.toUpperCase(),
                style: MooditType.monoLabel.copyWith(letterSpacing: 2),
              ),
              Text(
                currentValue.toStringAsFixed(0),
                style: MooditType.monoLabel.copyWith(
                  color: MooditColors.baseAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: AppSliderTheme.of(context),
            child: Slider(
              min: vm.selectedOperation.minValue,
              max: vm.selectedOperation.maxValue,
              value: currentValue,
              onChangeStart: (_) => vm.beginManualEdit(),
              onChanged: (value) {
                vm.updateEditPreview(
                  Edit(type: vm.selectedOperation, value: value),
                );
              },
              onChangeEnd: (value) {
                vm.applyEdit(Edit(type: vm.selectedOperation, value: value));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: vm.selectedOperation.minValue == 0
                  ? [
                      Text('0', style: MooditType.monoMeta),
                      Text('+100', style: MooditType.monoMeta),
                    ]
                  : [
                      Text('-100', style: MooditType.monoMeta),
                      Text('0', style: MooditType.monoMeta),
                      Text('+100', style: MooditType.monoMeta),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationBar() {
    final pendingAiGradient = aiProviderGradient(vm.pendingAiProviderId);

    return SizedBox(
      height: 64,
      child: Theme(
        data: ThemeData(
          scrollbarTheme: const ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(MooditColors.hairlineStrong),
            thickness: WidgetStatePropertyAll(3),
            radius: Radius.circular(2),
            minThumbLength: 40,
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            itemCount: OperationType.values.length,
            itemBuilder: (context, index) {
              final operation = OperationType.values[index];
              final isSelected = operation == vm.selectedOperation;
              final hasEdit = vm.hasEdit(operation);
              final isPendingAiEdit = vm.hasPendingEdits && vm.pendingAiEditTypes.contains(operation);
              final icon = _operationIcons[operation] ?? Icons.tune;

              return GestureDetector(
                onTap: () => vm.setSelectedOperation(operation),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MooditColors.baseAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(MooditDims.controlRadius),
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: (operation == OperationType.highlights || operation == OperationType.vibrance)
                              ? Matrix4.diagonal3Values(-1, 1, 1)
                              : Matrix4.identity(),
                          child: Icon(
                            icon,
                            size: 28,
                            color: isSelected
                                ? MooditColors.bgInner
                                : MooditColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: hasEdit ? 1.0 : 0.0,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
