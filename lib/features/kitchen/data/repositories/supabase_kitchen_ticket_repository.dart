import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_ticket_repository.dart';

class SupabaseKitchenTicketRepository implements KitchenTicketRepository {
  SupabaseKitchenTicketRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<KitchenTicket>> getTickets(String restaurantId) async {
    final rows = await _client
        .from('kitchen_tickets')
        .select('''
          id, restaurant_id, order_id, status, created_at,
          orders!inner(order_number, order_type, notes, dining_tables(label)),
          kitchen_ticket_items(id, notes, order_items(item_name, quantity))
        ''')
        .eq('restaurant_id', restaurantId)
        .inFilter('status', const ['queued', 'preparing', 'ready'])
        .order('created_at');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Stream<List<KitchenTicket>> watchTickets(String restaurantId) async* {
    yield await getTickets(restaurantId);
    final refreshes = StreamController<void>();
    final channel = _client
        .channel('kitchen-tickets-$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'kitchen_tickets',
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
          table: 'dining_tables',
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
        yield await getTickets(restaurantId);
      }
    } finally {
      await _client.removeChannel(channel);
      await refreshes.close();
    }
  }

  @override
  Future<void> updateStatus({
    required String ticketId,
    required KitchenTicketStatus nextStatus,
  }) => _client.rpc(
    'update_kitchen_ticket_status',
    params: {'p_ticket_id': ticketId, 'p_status': nextStatus.name},
  );

  KitchenTicket _fromRow(Map<String, dynamic> row) {
    final order = row['orders'] as Map<String, dynamic>;
    final table = order['dining_tables'] as Map<String, dynamic>?;
    final itemRows = (row['kitchen_ticket_items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return KitchenTicket(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      orderId: row['order_id'] as String,
      orderNumber: order['order_number'] as int,
      orderType: order['order_type'] as String,
      status: KitchenTicketStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      tableLabel: table?['label'] as String?,
      notes: order['notes'] as String?,
      items: itemRows
          .map((item) {
            final orderItem = item['order_items'] as Map<String, dynamic>;
            return KitchenTicketItem(
              id: item['id'] as String,
              name: orderItem['item_name'] as String,
              quantity: orderItem['quantity'] as num,
              notes: item['notes'] as String?,
            );
          })
          .toList(growable: false),
    );
  }
}
