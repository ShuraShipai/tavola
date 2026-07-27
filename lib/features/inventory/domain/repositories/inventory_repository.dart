import '../entities/inventory_item.dart';

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> getInventoryItems(String restaurantId);
  Future<void> recordMovement({
    required String itemId,
    required String movementType,
    required double quantityDelta,
    int? unitCostAmount,
    String? note,
  });
}
