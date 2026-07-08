import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qyclass/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const QYClassApp());
    // Verify the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
