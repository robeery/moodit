import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:licenta/view/shared/app_dialog.dart';

void main() {
  testWidgets('text input dialog returns the typed value, not the initial one',
      (tester) async {
    String? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showAppTextInputDialog(
                context,
                title: 'RENAME VERSION',
                initialValue: 'Version 1',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Client option');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(result, 'Client option');
  });
}
