import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/billing_repository.dart';

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<Bill>> getBills(String restaurantId) async {
    final rows = await _client
        .from('orders')
        .select(
          'id, order_number, status, total_amount, order_items(item_name, quantity, line_total_amount, notes), payments(amount, status)',
        )
        .eq('restaurant_id', restaurantId)
        .inFilter('status', ['served', 'billed', 'paid'])
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) {
          final payments = ((row['payments'] as List<dynamic>?) ?? const [])
              .cast<Map<String, dynamic>>();
          final paid = payments
              .where((payment) => payment['status'] == 'completed')
              .fold<int>(0, (sum, payment) => sum + payment['amount'] as int);
          return Bill(
            orderId: row['id'] as String,
            orderNumber: row['order_number'] as int,
            status: BillStatus.values.byName(row['status'] as String),
            totalAmount: row['total_amount'] as int,
            paidAmount: paid,
            lines: ((row['order_items'] as List<dynamic>?) ?? const [])
                .cast<Map<String, dynamic>>()
                .map(
                  (line) => BillLine(
                    name: line['item_name'] as String,
                    quantity: line['quantity'] as num,
                    lineTotalAmount: line['line_total_amount'] as int,
                    notes: line['notes'] as String?,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  @override
  Stream<List<Bill>> watchBills(String restaurantId) async* {
    yield await getBills(restaurantId);
    final refreshes = StreamController<void>();
    final channel = _client
        .channel('billing-$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (_) => refreshes.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (_) => refreshes.add(null),
        )
        .subscribe();
    try {
      await for (final _ in refreshes.stream) {
        yield await getBills(restaurantId);
      }
    } finally {
      await _client.removeChannel(channel);
      await refreshes.close();
    }
  }

  @override
  Future<void> collectPayment({
    required String orderId,
    required PaymentMethod method,
    required int amount,
    String? externalReference,
  }) => _client.rpc(
    'collect_order_payment',
    params: {
      'p_order_id': orderId,
      'p_payment_method': method.databaseValue,
      'p_amount': amount,
      'p_external_reference': externalReference,
    },
  );
}
