import 'package:flutter/material.dart';

import '../../../theme/slider_theme.dart';
import '../../../theme/app_theme.dart';

// Shared slider row for the color and grading panels: a label, a slider that
// can paint a gradient track behind it, and a value readout.
class GradientSliderRow extends StatelessWidget {
  const GradientSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
    this.gradient,
    this.valueWidth = 32,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueText;
  final List<Color>? gradient;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final track = gradient;
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label, style: MooditType.monoMeta)),
        Expanded(
          child: track != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: LinearGradient(colors: track),
                        ),
                      ),
                    ),
                    SliderTheme(
                      data: AppSliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: _slider(),
                    ),
                  ],
                )
              : SliderTheme(
                  data: AppSliderTheme.of(context),
                  child: _slider(),
                ),
        ),
        SizedBox(
          width: valueWidth,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: MooditType.monoMeta.copyWith(color: MooditColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Slider _slider() {
    return Slider(
      min: min,
      max: max,
      value: value,
      onChangeStart: (_) => onChangeStart(),
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
    );
  }
}
