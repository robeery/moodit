import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

// Shared cinematic dialogs so every popup has the same look and we avoid 
// repeating the AlertDialog boilerplate in each screen

TextButton appDialogButton(
  BuildContext ctx,
  String label,
  Object? popValue, {
  Color color = MooditColors.baseAccent,
}) {
  return TextButton(
    onPressed: () => Navigator.of(ctx).pop(popValue),
    child: Text(label, style: MooditType.monoMeta.copyWith(color: color)),
  );
}

AlertDialog appDialogShell({
  String? title,
  required Widget content,
  List<Widget>? actions,
}) {
  return AlertDialog(
    backgroundColor: MooditColors.cardAlt,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MooditDims.cardRadius),
    ),
    title: title == null ? null : Text(title, style: MooditType.screenTitle),
    content: content,
    actions: actions,
  );
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'CANCEL',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => appDialogShell(
      title: title,
      content: Text(message, style: MooditType.bodyText),
      actions: [
        appDialogButton(ctx, cancelLabel, false, color: MooditColors.textMuted),
        appDialogButton(
          ctx,
          confirmLabel,
          true,
          color: destructive
              ? MooditColors.destructive
              : MooditColors.baseAccent,
        ),
      ],
    ),
  );
  return result ?? false;
}


Future<String?> showAppTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? label,
  String? hint,
  int? maxLength,
  String confirmLabel = 'SAVE',
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _TextInputDialog(
      title: title,
      initialValue: initialValue,
      label: label,
      hint: hint,
      maxLength: maxLength,
      confirmLabel: confirmLabel,
    ),
  );
}


class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initialValue,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String? label;
  final String? hint;
  final int? maxLength;
  final String confirmLabel;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return appDialogShell(
      title: widget.title,
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        inputFormatters: widget.maxLength == null
            ? null
            : [LengthLimitingTextInputFormatter(widget.maxLength!)],
        style: MooditType.bodyText,
        cursorColor: MooditColors.baseAccent,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          counterText: widget.maxLength == null ? null : '',
          labelStyle: MooditType.monoMeta,
          hintStyle:
              MooditType.bodySecondary.copyWith(color: MooditColors.textOff),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: MooditColors.hairline),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: MooditColors.baseAccent),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        appDialogButton(context, 'CANCEL', null, color: MooditColors.textMuted),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: MooditType.monoMeta.copyWith(color: MooditColors.baseAccent),
          ),
        ),
      ],
    );
  }
}

class AppDialogAction<T> {
  const AppDialogAction(this.label, this.value, {this.color});

  final String label;
  final T value;
  final Color? color;
}

Future<T?> showAppChoiceDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  required List<AppDialogAction<T>> actions,
  String? cancelLabel = 'CANCEL',
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => appDialogShell(
      title: title,
      content: Text(message, style: MooditType.bodyText),
      actions: [
        if (cancelLabel != null)
          appDialogButton(ctx, cancelLabel, null, color: MooditColors.textMuted),
        for (final action in actions)
          appDialogButton(
            ctx,
            action.label,
            action.value,
            color: action.color ?? MooditColors.baseAccent,
          ),
      ],
    ),
  );
}


Future<void> showAppMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => appDialogShell(
      title: title,
      content: Text(message, style: MooditType.bodyText),
      actions: [appDialogButton(ctx, buttonLabel, null)],
    ),
  );
}
