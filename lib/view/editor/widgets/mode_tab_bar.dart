import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';
import '../../../viewmodel/editor_viewmodel.dart';

class ModeTabBar extends StatelessWidget {
  final EditorMode currentMode;
  final ValueChanged<EditorMode> onModeChanged;
  final bool hasPendingBasicEdits;
  final bool hasPendingColorEdits;
  final bool hasPendingGradingEdits;
  final LinearGradient pendingAiGradient;

  const ModeTabBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.hasPendingBasicEdits = false,
    this.hasPendingColorEdits = false,
    this.hasPendingGradingEdits = false,
    this.pendingAiGradient = const LinearGradient(
      colors: [Color(0xFF4C8DF6), Color(0xFF9B5CF6)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  });

  static const _modes = [
    (mode: EditorMode.basic,          icon: Icons.tune,              label: 'BASIC'),
    (mode: EditorMode.selectiveColor, icon: Icons.palette_outlined,  label: 'COLOR'),
    (mode: EditorMode.colorGrading,   icon: Icons.motion_photos_on ,      label: 'GRADING'),
    (mode: EditorMode.askAi,          icon: Icons.auto_awesome,      label: 'AI'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      //might have to tweak these values later on other devices
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 16, right:16),
      decoration: const BoxDecoration(
        color: MooditColors.card,
        border: Border(
          bottom: BorderSide(color: MooditColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _modes.map((m) {
          final isActive = currentMode == m.mode;
          final hasPending = switch (m.mode) {
            EditorMode.basic => hasPendingBasicEdits,
            EditorMode.selectiveColor => hasPendingColorEdits,
            EditorMode.colorGrading => hasPendingGradingEdits,
            _ => false,
          };
          return GestureDetector(
            onTap: () => onModeChanged(m.mode),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  m.icon,
                  size: 16,
                  color: isActive
                      ? MooditColors.baseAccent
                      : MooditColors.textMuted,
                ),
                const SizedBox(height: 1),
                hasPending
                    ? ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            pendingAiGradient.createShader(bounds),
                        child: Padding(
                          // this padding makes it so the shader mask doesn't get cut off above the text
                          padding: const EdgeInsets.symmetric(vertical: 0.2),
                          child: Text(
                            m.label,
                            style: const TextStyle(
                              fontFamily: MooditType.mono,
                              color: Colors.white,
                              fontSize: 8,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        // this padding is here so the UI matches the mode above
                        padding: const EdgeInsets.symmetric(vertical: 0.2),
                        child: Text(
                          m.label,
                          style: TextStyle(
                            fontFamily: MooditType.mono,
                            color: isActive
                                ? MooditColors.baseAccent
                                : MooditColors.textMuted,
                            fontSize: 8,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
