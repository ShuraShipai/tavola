import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/dining_table.dart';
import '../../domain/repositories/dining_table_repository.dart';

class SupabaseDiningTableRepository implements DiningTableRepository {
  SupabaseDiningTableRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<DiningTable>> getTables(String restaurantId) async {
    try {
      final rows = await _client
          .from('dining_tables')
          .select(
            'id, restaurant_id, branch_id, label, capacity, status, sort_order, version, current_status_detail',
          )
          .eq('restaurant_id', restaurantId)
          .order('sort_order')
          .order('label')
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException(
              'Dining-table request timed out. Check Supabase connectivity and refresh.',
            ),
          );
      final tables = (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_fromRow)
          .toList(growable: false);
      tables.sort(
        (left, right) =>
            _tableNumber(left.label).compareTo(_tableNumber(right.label)),
      );
      return tables;
    } on PostgrestException catch (error) {
      if (error.code == '42703') {
        throw StateError(
          error.message.contains('current_status_detail')
              ? 'The editable table-status migration has not been applied. '
                    'Run 20260728113000_table_editor_workflow.sql in Supabase.'
              : 'The Tables database migration has not been applied. Run '
                    '20260725140000_complete_pos_operations.sql in Supabase.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> saveTable({
    required String restaurantId,
    String? tableId,
    String? branchId,
    required String label,
    required int capacity,
    required int sortOrder,
    String? currentStatusDetail,
  }) async {
    try {
      await _client.rpc(
        'save_dining_table',
        params: {
          'p_restaurant_id': restaurantId,
          'p_table_id': tableId,
          'p_branch_id': branchId,
          'p_label': label.trim(),
          'p_capacity': capacity,
          'p_sort_order': sortOrder,
          'p_current_status_detail': currentStatusDetail?.trim(),
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') {
        throw StateError(
          'The Table Editor migration is outdated. Run '
          '20260728113000_table_editor_workflow.sql again in Supabase.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteTable({required String tableId}) =>
      _client.rpc('delete_dining_table', params: {'p_table_id': tableId});

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
    String? currentStatusDetail,
  }) async {
    await _client
        .from('dining_tables')
        .update({
          'status': status.name,
          'current_status_detail': currentStatusDetail ?? status.label,
        })
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
    currentStatusDetail: row['current_status_detail'] as String?,
  );

  int _tableNumber(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return match == null ? 1 << 30 : int.parse(match.group(0)!);
  }
}
