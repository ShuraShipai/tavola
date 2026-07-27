import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/tables/domain/entities/dining_table.dart';
import 'package:tavola/features/tables/domain/repositories/dining_table_repository.dart';
import 'package:tavola/features/tables/domain/usecases/get_restaurant_tables.dart';
import 'package:tavola/features/tables/domain/usecases/update_dining_table_status.dart';

void main() {
  test('gets dining tables for the requested restaurant only', () async {
    final repository = _FakeDiningTableRepository();
    final result = await GetRestaurantTables(repository)('restaurant-a');

    expect(repository.requestedRestaurantId, 'restaurant-a');
    expect(result.single.label, 'Table 1');
  });

  test('updates a table status within the requested restaurant', () async {
    final repository = _FakeDiningTableRepository();

    await UpdateDiningTableStatus(repository)(
      restaurantId: 'restaurant-a',
      tableId: 'table-1',
      status: DiningTableStatus.unavailable,
    );

    expect(repository.updatedRestaurantId, 'restaurant-a');
    expect(repository.updatedTableId, 'table-1');
    expect(repository.updatedStatus, DiningTableStatus.unavailable);
  });
}

class _FakeDiningTableRepository implements DiningTableRepository {
  String? requestedRestaurantId;
  String? updatedRestaurantId;
  String? updatedTableId;
  DiningTableStatus? updatedStatus;

  @override
  Future<List<DiningTable>> getTables(String restaurantId) async {
    requestedRestaurantId = restaurantId;
    return [
      const DiningTable(
        id: 'table-1',
        restaurantId: 'restaurant-a',
        branchId: 'branch-1',
        label: 'Table 1',
        capacity: 4,
        status: DiningTableStatus.available,
        sortOrder: 1,
      ),
    ];
  }

  @override
  Stream<List<DiningTable>> watchTables(String restaurantId) =>
      Stream.value(const []);

  @override
  Future<void> seatTable({
    required String tableId,
    required int expectedVersion,
  }) async {}

  @override
  Future<void> assignOrder({
    required String orderId,
    required String tableId,
    required int expectedTableVersion,
  }) async {}

  @override
  Future<String> mergeTables({
    required String primaryTableId,
    required List<String> secondaryTableIds,
  }) async => 'merge-1';

  @override
  Future<void> splitMerge(String mergeId) async {}

  @override
  Future<void> updateStatus({
    required String restaurantId,
    required String tableId,
    required DiningTableStatus status,
  }) async {
    updatedRestaurantId = restaurantId;
    updatedTableId = tableId;
    updatedStatus = status;
  }
}
