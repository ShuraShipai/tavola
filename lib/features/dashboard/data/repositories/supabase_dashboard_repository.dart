import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<DashboardSnapshot> getSnapshot(
    String restaurantId,
    DateTime now,
  ) async {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 6));
    final responses = await Future.wait([
      _client
          .from('orders')
          .select(
            'id,order_number,status,total_amount,created_at,order_type,table:dining_tables(label),order_items(item_name,quantity)',
          )
          .eq('restaurant_id', restaurantId)
          .gte('created_at', today.toIso8601String())
          .lt('created_at', tomorrow.toIso8601String())
          .neq('status', 'cancelled'),
      _client
          .from('orders')
          .select('total_amount,created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', weekStart.toIso8601String())
          .lt('created_at', tomorrow.toIso8601String())
          .neq('status', 'cancelled'),
      _client
          .from('dining_tables')
          .select('status')
          .eq('restaurant_id', restaurantId),
      _client
          .from('orders')
          .select(
            'id,order_number,status,total_amount,created_at,order_type,table:dining_tables(label),order_items(item_name,quantity)',
          )
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false)
          .limit(8),
    ]);
    final todayOrders = _rows(responses[0]);
    final weeklyOrders = _rows(responses[1]);
    final tables = _rows(responses[2]);
    final recent = _rows(responses[3]);
    final sales = todayOrders.fold<int>(
      0,
      (sum, row) => sum + _int(row['total_amount']),
    );
    final top = <String, num>{};
    for (final order in todayOrders) {
      for (final item in _nestedRows(order['order_items'])) {
        final name = item['item_name'] as String? ?? 'Unnamed item';
        top[name] = (top[name] ?? 0) + _num(item['quantity']);
      }
    }
    final weekly = <DailySales>[];
    for (var offset = 0; offset < 7; offset++) {
      final day = weekStart.add(Duration(days: offset));
      final amount = weeklyOrders
          .where(
            (row) =>
                _date(row['created_at']).year == day.year &&
                _date(row['created_at']).month == day.month &&
                _date(row['created_at']).day == day.day,
          )
          .fold<int>(0, (sum, row) => sum + _int(row['total_amount']));
      weekly.add(
        DailySales(label: DateFormat('E').format(day), amount: amount),
      );
    }
    return DashboardSnapshot(
      todaySalesAmount: sales,
      todayOrderCount: todayOrders.length,
      occupiedTables: tables.where((row) => row['status'] == 'occupied').length,
      totalTables: tables.length,
      reservedTables: tables.where((row) => row['status'] == 'reserved').length,
      weeklySales: weekly,
      topItems:
          (top.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .take(4)
              .map(
                (entry) =>
                    TopSellingItem(name: entry.key, quantity: entry.value),
              )
              .toList(growable: false),
      recentOrders: recent.map(_orderFromRow).toList(growable: false),
    );
  }

  List<Map<String, dynamic>> _rows(dynamic response) =>
      (response as List<dynamic>).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> _nestedRows(dynamic value) =>
      value is List<dynamic> ? value.cast<Map<String, dynamic>>() : const [];
  int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
  DateTime _date(dynamic value) => DateTime.parse(value as String).toLocal();
  DashboardOrder _orderFromRow(Map<String, dynamic> row) {
    final table = row['table'];
    final items = _nestedRows(row['order_items']);
    return DashboardOrder(
      id: row['id'] as String,
      number: _int(row['order_number']),
      status: row['status'] as String? ?? 'draft',
      orderType: row['order_type'] as String? ?? 'dine_in',
      totalAmount: _int(row['total_amount']),
      createdAt: _date(row['created_at']),
      tableLabel: table is Map<String, dynamic>
          ? table['label'] as String?
          : null,
      itemSummary: items
          .map((item) => '${item['item_name']} ×${_num(item['quantity'])}')
          .join(', '),
    );
  }
}
