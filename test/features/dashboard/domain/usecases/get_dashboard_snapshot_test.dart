import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/dashboard/domain/entities/dashboard_snapshot.dart';
import 'package:tavola/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tavola/features/dashboard/domain/usecases/get_dashboard_snapshot.dart';

void main() {
  test('loads a snapshot for the active restaurant and current time', () async {
    final repository = _DashboardRepository();
    final now = DateTime.utc(2026, 7, 25);
    final snapshot = await GetDashboardSnapshot(repository)(
      'restaurant-1',
      now,
    );
    expect(repository.restaurantId, 'restaurant-1');
    expect(repository.now, now);
    expect(snapshot.todayOrderCount, 2);
  });
}

class _DashboardRepository implements DashboardRepository {
  String? restaurantId;
  DateTime? now;
  @override
  Future<DashboardSnapshot> getSnapshot(String id, DateTime time) async {
    restaurantId = id;
    now = time;
    return const DashboardSnapshot(
      todaySalesAmount: 20000,
      todayOrderCount: 2,
      occupiedTables: 1,
      totalTables: 4,
      reservedTables: 1,
      weeklySales: [],
      topItems: [],
      recentOrders: [],
    );
  }
}
