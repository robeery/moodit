import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_tokens.dart';

// Shared cinematic dialogs so every popup has the same look and we avoid
// repeating the AlertDialog boilerplate in each screen.

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

// Yes/No style confirmation. Returns false when dismissed.
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

// Single text field dialog. Returns the entered text, or null on cancel.
Future<String?> showAppTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? label,
  String? hint,
  int? maxLength,
  String confirmLabel = 'SAVE',
}) async {
  final controller = TextEditingController(text: initialValue);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => appDialogShell(
      title: title,
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        inputFormatters: maxLength == null
            ? null
            : [LengthLimitingTextInputFormatter(maxLength)],
        style: MooditType.bodyText,
        cursorColor: MooditColors.baseAccent,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: maxLength == null ? null : '',
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
        onSubmitted: (value) => Navigator.of(ctx).pop(value),
      ),
      actions: [
        appDialogButton(ctx, 'CANCEL', null, color: MooditColors.textMuted),
        appDialogButton(ctx, confirmLabel, controller.text),
      ],
    ),
  );

  controller.dispose();
  return result;
}

class AppDialogAction<T> {
  const AppDialogAction(this.label, this.value, {this.color});

  final String label;
  final T value;
  final Color? color;
}

// Dialog with several positive choices plus an optional cancel button.
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

// Informational popup with a single dismiss button.
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
