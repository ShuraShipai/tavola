import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/dining_table.dart';
import '../../domain/repositories/dining_table_repository.dart';

class SupabaseDiningTableRepository implements DiningTableRepository {
  SupabaseDiningTableRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<DiningTable>> getTables(String restaurantId) async {
    final rows = await _client
        .from('dining_tables')
        .select(
          'id, restaurant_id, branch_id, label, capacity, status, sort_order, version',
        )
        .eq('restaurant_id', restaurantId)
        .order('sort_order')
        .order('label');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromRow)
        .toList(growable: false);
  }

  @override
  Future<void> seatTable({
    required String tableId,
    required int expectedVersion,
  }) => _client.rpc(
    'seat_table',
    params: {'p_table_id': tableId, 'p_expected_version': expectedVersion},
  );

  @override
  Future<void> assignOrder({
    required String orderId,
    required String tableId,
    required int expectedTableVersion,
  }) => _client.rpc(
    'assign_order_table',
    params: {
      'p_order_id': orderId,
      'p_table_id': tableId,
      'p_expected_table_version': expectedTableVersion,
    },
  );

  @override
  Future<String> mergeTables({
    required String primaryTableId,
    required List<String> secondaryTableIds,
  }) async =>
      await _client.rpc(
            'merge_tables',
            params: {
              'p_primary_table_id': primaryTableId,
              'p_secondary_table_ids': secondaryTableIds,
            },
          )
          as String;

  @override
  Future<void> splitMerge(String mergeId) =>
      _client.rpc('split_table_merge', params: {'p_merge_id': mergeId});

  @override
  Stream<List<DiningTable>> watchTables(String restaurantId) async* {
    yield await getTables(restaurantId);
    final refreshes = StreamController<void>();
    final channel = _client
        .channel('tables-$restaurantId')
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
        .subscribe();
    try {
      await for (final _ in refreshes.stream) {
        yield await getTables(restaurantId);
      }
    } finally {
      await _client.removeChannel(channel);
      await refreshes.close();
    }
  }

  @override
  Future<void> updateStatus({
    required String restaurantId,
    required String tableId,
    required DiningTableStatus status,
  }) async {
    await _client
        .from('dining_tables')
        .update({'status': status.name})
        .eq('id', tableId)
        .eq('restaurant_id', restaurantId);
  }

  DiningTable _fromRow(Map<String, dynamic> row) => DiningTable(
    id: row['id'] as String,
    restaurantId: row['restaurant_id'] as String,
    branchId: row['branch_id'] as String,
    label: row['label'] as String,
    capacity: row['capacity'] as int,
    status: DiningTableStatus.values.byName(row['status'] as String),
    sortOrder: row['sort_order'] as int,
    version: row['version'] as int? ?? 1,
  );
}
