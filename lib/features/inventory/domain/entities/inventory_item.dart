class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentQuantity,
    required this.reorderLevel,
    required this.unitCostAmount,
    required this.isActive,
  });
  final String id;
  final String restaurantId;
  final String name;
  final String? sku;
  final String unit;
  final double currentQuantity;
  final double reorderLevel;
  final int? unitCostAmount;
  final bool isActive;
}

extension InventoryItemX on InventoryItem {
  bool get isOutOfStock => currentQuantity <= 0;
  bool get isLowStock => !isOutOfStock && currentQuantity <= reorderLevel;
}
