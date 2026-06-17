import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HistoryActionBar extends StatefulWidget {
  final bool visible;
  final IconData icon;
  final String message;

  const HistoryActionBar({
    super.key,
    required this.visible,
    required this.icon,
    required this.message,
  });

  @override
  State<HistoryActionBar> createState() => _HistoryActionBarState();
}

class _HistoryActionBarState extends State<HistoryActionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HistoryActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: MooditColors.cardAlt.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(widget.icon, color: MooditColors.baseAccent, size: 15),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: MooditType.monoLabel.copyWith(letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
