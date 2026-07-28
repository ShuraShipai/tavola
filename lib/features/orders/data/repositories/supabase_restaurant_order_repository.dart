import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/restaurant_order.dart';
import '../../domain/repositories/restaurant_order_repository.dart';

class SupabaseRestaurantOrderRepository implements RestaurantOrderRepository {
  SupabaseRestaurantOrderRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<RestaurantOrder>> getOrders(String restaurantId) async {
    final rows = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Stream<List<RestaurantOrder>> watchOrders(String restaurantId) async* {
    yield await getOrders(restaurantId);
    final refreshes = StreamController<void>();
    final channel = _client
        .channel('orders-$restaurantId')
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
          table: 'order_items',
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
        yield await getOrders(restaurantId);
      }
    } finally {
      await _client.removeChannel(channel);
      await refreshes.close();
    }
  }

  @override
  Future<RestaurantOrder> createOrder(CreateOrderInput input) async {
    final orderId =
        await _client.rpc(
              'create_order',
              params: {
                'p_restaurant_id': input.restaurantId,
                'p_items': _itemsPayload(input.items),
                'p_table_id': input.tableId,
                'p_customer_id': input.customerId,
                'p_order_type': _snakeCase(input.orderType.name),
                'p_notes': input.notes,
              },
            )
            as String;
    return _getOrder(orderId, input.restaurantId);
  }

  @override
  Future<RestaurantOrder> createHeldOrder(CreateOrderInput input) async {
    final orderId =
        await _client.rpc(
              'create_held_order',
              params: {
                'p_restaurant_id': input.restaurantId,
                'p_items': _itemsPayload(input.items),
                'p_table_id': input.tableId,
                'p_order_type': _snakeCase(input.orderType.name),
                'p_notes': input.notes,
              },
            )
            as String;
    return _getOrder(orderId, input.restaurantId);
  }

  @override
  Future<RestaurantOrder> updateOrder(UpdateOrderInput input) async {
    final orderId =
        await _client.rpc(
              'update_order',
              params: {
                'p_order_id': input.orderId,
                'p_restaurant_id': input.restaurantId,
                'p_items': _itemsPayload(input.items),
                'p_table_id': input.tableId,
                'p_customer_id': input.customerId,
                'p_order_type': _snakeCase(input.orderType.name),
                'p_notes': input.notes,
              },
            )
            as String;
    return _getOrder(orderId, input.restaurantId);
  }

  @override
  Future<RestaurantOrder> transitionOrder({
    required String restaurantId,
    required String orderId,
    required RestaurantOrderStatus from,
    required RestaurantOrderStatus to,
  }) async {
    await _client.rpc(
      'transition_order_status',
      params: {
        'p_order_id': orderId,
        'p_restaurant_id': restaurantId,
        'p_to_status': _snakeCase(to.name),
      },
    );
    return _getOrder(orderId, restaurantId);
  }

  @override
  Future<RestaurantOrder> cancelOrder({
    required String restaurantId,
    required String orderId,
    required String reason,
  }) async {
    await _client.rpc(
      'cancel_restaurant_order',
      params: {
        'p_order_id': orderId,
        'p_restaurant_id': restaurantId,
        'p_reason': reason,
      },
    );
    return _getOrder(orderId, restaurantId);
  }

  Future<RestaurantOrder> _getOrder(String orderId, String restaurantId) async {
    final row = await _client
        .from('orders')
        .select(_orderSelect)
        .eq('id', orderId)
        .eq('restaurant_id', restaurantId)
        .single();
    return _fromRow(row);
  }

  RestaurantOrder _fromRow(Map<String, dynamic> row) => RestaurantOrder(
    id: row['id'] as String,
    restaurantId: row['restaurant_id'] as String,
    orderNumber: row['order_number'] as int,
    status: RestaurantOrderStatus.values.byName(
      _camelCase(row['status'] as String),
    ),
    orderType: RestaurantOrderType.values.byName(
      _camelCase(row['order_type'] as String),
    ),
    totalAmount: row['total_amount'] as int,
    createdAt: DateTime.parse(row['created_at'] as String),
    openedAt: row['opened_at'] == null
        ? null
        : DateTime.parse(row['opened_at'] as String),
    tableId: row['table_id'] as String?,
    customerId: row['customer_id'] as String?,
    notes: row['notes'] as String?,
    items: ((row['order_items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (item) => OrderLine(
            menuItemId: item['menu_item_id'] as String?,
            name: item['item_name'] as String,
            unitPriceAmount: item['unit_price_amount'] as int,
            quantity: item['quantity'] as num,
            taxAmount: item['tax_amount'] as int,
            lineTotalAmount: item['line_total_amount'] as int,
            notes: item['notes'] as String?,
          ),
        )
        .toList(growable: false),
  );

  String _camelCase(String value) {
    final parts = value.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join();
  }

  List<Map<String, dynamic>> _itemsPayload(List<OrderItemInput> items) => items
      .map(
        (item) => {
          'menu_item_id': item.menuItemId,
          'quantity': item.quantity,
          'notes': item.notes,
        },
      )
      .toList(growable: false);

  String _snakeCase(String value) => value.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

const _orderSelect =
    'id, restaurant_id, order_number, status, order_type, '
    'total_amount, created_at, opened_at, table_id, customer_id, notes, '
    'order_items(menu_item_id, item_name, unit_price_amount, quantity, '
    'tax_amount, line_total_amount, notes)';
