import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/reports/presentation/pages/reports_page.dart';

void main() {
  testWidgets('renders the reports dashboard without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReportsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Revenue trend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
