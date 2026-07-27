import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tavola/features/reports/presentation/pages/reports_page.dart';
import 'package:tavola/features/reports/domain/entities/restaurant_report.dart';
import 'package:tavola/features/reports/presentation/providers/report_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  testWidgets('renders the reports dashboard without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantReportProvider.overrideWithValue(
            AsyncData(
              RestaurantReport(
                periodStart: DateTime(2026, 1, 1),
                periodEnd: DateTime(2026, 1, 7),
                netSalesAmount: 1000,
                orderCount: 1,
                refundAmount: 0,
                dailySales: [
                  DailySales(date: DateTime(2026, 1, 1), amount: 1000),
                ],
                paymentMix: [PaymentMethodTotal(method: 'Cash', amount: 1000)],
                recentPayments: [
                  ReportPayment(
                    orderId: 'order-1',
                    method: 'Cash',
                    amount: 1000,
                    paidAt: DateTime(2026, 1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ReportsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('Revenue trend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
