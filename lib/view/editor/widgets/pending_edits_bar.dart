import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

class PendingEditsBar extends StatefulWidget {
  final VoidCallback onApply;
  final VoidCallback onDiscard;
  final LinearGradient aiGradient;

  const PendingEditsBar({
    super.key,
    required this.onApply,
    required this.onDiscard,
    this.aiGradient = const LinearGradient(
      colors: [Color(0xFF4C8DF6), Color(0xFF9B5CF6)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  });

  @override
  State<PendingEditsBar> createState() => _PendingEditsBarState();
}

class _PendingEditsBarState extends State<PendingEditsBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateOut(VoidCallback onDone) {
    _controller.reverse().then((_) => onDone());
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: MooditColors.cardAlt.withValues(alpha: 0.92),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.aiGradient,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'APPLY CHANGES?',
              style: MooditType.monoLabel.copyWith(letterSpacing: 2),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _animateOut(widget.onDiscard),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MooditDims.controlRadius),
                  border: Border.all(color: MooditColors.hairlineStrong),
                ),
                child: Text(
                  'DISCARD',
                  style: MooditType.monoMeta.copyWith(
                    color: MooditColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _animateOut(widget.onApply),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: widget.aiGradient,
                  borderRadius: BorderRadius.circular(MooditDims.controlRadius),
                ),
                child: Text(
                  'APPLY',
                  style: MooditType.monoMeta.copyWith(
                    color: MooditColors.bgInner,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
