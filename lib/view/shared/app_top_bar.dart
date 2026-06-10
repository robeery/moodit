import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

// Cinematic top bar: circular back button, centered mono title and an optional
// trailing action. Shared by the settings and project detail screens.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MooditDims.screenPadding,
        6,
        MooditDims.screenPadding,
        6,
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleButton(icon: Icons.arrow_back, onTap: onBack),
            ),
            Text(title, style: MooditType.screenTitle),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MooditColors.surfaceSubtle,
          border: Border.all(color: MooditColors.hairline),
        ),
        child: Icon(icon, color: MooditColors.textPrimary, size: 18),
      ),
    );
  }
}

// Mono text action used in the top bar trailing slot (e.g. SAVE).
class TopBarTextAction extends StatelessWidget {
  const TopBarTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.color = MooditColors.baseAccent,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(
        label,
        style: MooditType.monoLabel.copyWith(
          color: enabled ? color : MooditColors.textOff,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
