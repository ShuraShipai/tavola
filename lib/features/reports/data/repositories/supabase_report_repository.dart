import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/restaurant_report.dart';
import '../../domain/repositories/report_repository.dart';

class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<RestaurantReport> getReport({
    required String restaurantId,
    required DateTime periodEnd,
    int periodDays = 7,
  }) async {
    final end = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
    ).add(const Duration(days: 1));
    final start = end.subtract(Duration(days: periodDays.clamp(1, 90)));
    final paymentRows = await _client
        .from('payments')
        .select('order_id, payment_method, amount, paid_at')
        .eq('restaurant_id', restaurantId)
        .eq('status', 'completed')
        .gte('paid_at', start.toIso8601String())
        .lt('paid_at', end.toIso8601String())
        .order('paid_at', ascending: false);
    final refundRows = await _client
        .from('payment_refunds')
        .select('amount')
        .eq('restaurant_id', restaurantId)
        .gte('refunded_at', start.toIso8601String())
        .lt('refunded_at', end.toIso8601String());

    final payments = (paymentRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => ReportPayment(
            orderId: row['order_id'] as String,
            method: row['payment_method'] as String,
            amount: row['amount'] as int,
            paidAt: DateTime.parse(row['paid_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
    final refunds = (refundRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .fold<int>(0, (total, row) => total + (row['amount'] as int));
    final grossSales = payments.fold<int>(
      0,
      (total, payment) => total + payment.amount,
    );

    final totalsByDay = <DateTime, int>{
      for (
        var day = start;
        day.isBefore(end);
        day = day.add(const Duration(days: 1))
      )
        DateTime(day.year, day.month, day.day): 0,
    };
    final totalsByMethod = <String, int>{};
    for (final payment in payments) {
      final day = DateTime(
        payment.paidAt.year,
        payment.paidAt.month,
        payment.paidAt.day,
      );
      totalsByDay[day] = (totalsByDay[day] ?? 0) + payment.amount;
      totalsByMethod[payment.method] =
          (totalsByMethod[payment.method] ?? 0) + payment.amount;
    }

    return RestaurantReport(
      periodStart: start,
      periodEnd: end.subtract(const Duration(days: 1)),
      netSalesAmount: grossSales - refunds,
      orderCount: payments.map((payment) => payment.orderId).toSet().length,
      refundAmount: refunds,
      dailySales: totalsByDay.entries
          .map((entry) => DailySales(date: entry.key, amount: entry.value))
          .toList(growable: false),
      paymentMix: totalsByMethod.entries
          .map(
            (entry) =>
                PaymentMethodTotal(method: entry.key, amount: entry.value),
          )
          .toList(growable: false),
      recentPayments: payments.take(5).toList(growable: false),
    );
  }
}
