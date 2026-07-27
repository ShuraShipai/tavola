import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/reports/domain/entities/restaurant_report.dart';
import 'package:tavola/features/reports/domain/repositories/report_repository.dart';
import 'package:tavola/features/reports/domain/usecases/get_restaurant_report.dart';

void main() {
  test('gets a report only for the requested restaurant and period', () async {
    final repository = _FakeReportRepository();
    final end = DateTime.utc(2026, 7, 25);

    final result = await GetRestaurantReport(repository)(
      restaurantId: 'restaurant-a',
      periodEnd: end,
    );

    expect(repository.restaurantId, 'restaurant-a');
    expect(repository.periodEnd, end);
    expect(result.netSalesAmount, 12000);
  });
}

class _FakeReportRepository implements ReportRepository {
  String? restaurantId;
  DateTime? periodEnd;

  @override
  Future<RestaurantReport> getReport({
    required String restaurantId,
    required DateTime periodEnd,
    int periodDays = 7,
  }) async {
    this.restaurantId = restaurantId;
    this.periodEnd = periodEnd;
    return RestaurantReport(
      periodStart: periodEnd.subtract(const Duration(days: 6)),
      periodEnd: periodEnd,
      netSalesAmount: 12000,
      orderCount: 2,
      refundAmount: 0,
      dailySales: const [],
      paymentMix: const [],
      recentPayments: const [],
    );
  }
}
