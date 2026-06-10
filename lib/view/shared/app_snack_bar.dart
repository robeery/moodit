import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

// Tracks the visible toast so a new one replaces the old one cleanly.
VoidCallback? _dismissCurrentToast;

// Cinematic toast that slides up on enter and slides back down on exit.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  _dismissCurrentToast?.call();

  var removed = false;
  late OverlayEntry entry;
  void dismiss() {
    if (removed) return;
    removed = true;
    if (identical(_dismissCurrentToast, dismiss)) _dismissCurrentToast = null;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      isError: isError,
      onDismissed: dismiss,
    ),
  );
  _dismissCurrentToast = dismiss;
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.isError,
    required this.onDismissed,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  static const _inDuration = Duration(milliseconds: 280);
  static const _outDuration = Duration(milliseconds: 220);
  static const _holdDuration = Duration(milliseconds: 2200);

  late final AnimationController _controller;
  late final Animation<double> _anim;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _inDuration,
      reverseDuration: _outDuration,
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.forward();
    _holdTimer = Timer(_inDuration + _holdDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final accent =
        widget.isError ? MooditColors.destructive : MooditColors.baseAccent;

    return Positioned(
      left: 16,
      right: 16,
      bottom: media.viewInsets.bottom + media.padding.bottom + 20,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final t = _anim.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 28),
              child: child,
            ),
          );
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: MooditColors.cardAlt,
                  borderRadius:
                      BorderRadius.circular(MooditDims.controlRadius),
                  border: Border.all(color: MooditColors.hairline),
                  boxShadow: MooditDims.softDrop,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(widget.message, style: MooditType.bodyText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
