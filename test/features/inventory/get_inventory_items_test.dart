import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/inventory/domain/entities/inventory_item.dart';
import 'package:tavola/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:tavola/features/inventory/domain/usecases/get_inventory_items.dart';

void main() {
  test('passes the requested restaurant to inventory repository', () async {
    final repository = _Fake();
    final results = await GetInventoryItems(repository)('restaurant-a');
    expect(repository.restaurantId, 'restaurant-a');
    expect(results.single.name, 'Mozzarella');
  });
}

class _Fake implements InventoryRepository {
  String? restaurantId;
  @override
  Future<List<InventoryItem>> getInventoryItems(String id) async {
    restaurantId = id;
    return [
      InventoryItem(
        id: 'item-1',
        restaurantId: id,
        name: 'Mozzarella',
        sku: null,
        unit: 'kg',
        currentQuantity: 2,
        reorderLevel: 5,
        unitCostAmount: 52000,
        isActive: true,
      ),
    ];
  }

  @override
  Future<void> recordMovement({
    required String itemId,
    required String movementType,
    required double quantityDelta,
    int? unitCostAmount,
    String? note,
  }) async {}
}
