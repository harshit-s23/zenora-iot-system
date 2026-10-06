import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenora/main.dart';

void main() {
  testWidgets('app loads with the main navigation shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('AI Chat'), findsOneWidget);
  });
}
