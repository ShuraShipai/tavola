import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/app/tavola_app.dart';

void main() {
  testWidgets('shows the Tavola welcome screen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TavolaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Run your restaurant, front to back'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
