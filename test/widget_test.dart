import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:licenta/main.dart';

void main() {
  testWidgets('editor starts on the empty image state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('EDIT'), findsOneWidget);
    expect(find.text('Pick Image'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
