import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<InventoryItem>> getInventoryItems(String restaurantId) async {
    final rows = await _client
        .from('inventory_items')
        .select(
          'id, restaurant_id, name, sku, unit, current_quantity, reorder_level, unit_cost_amount, is_active',
        )
        .eq('restaurant_id', restaurantId)
        .order('name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => InventoryItem(
            id: row['id'] as String,
            restaurantId: row['restaurant_id'] as String,
            name: row['name'] as String,
            sku: row['sku'] as String?,
            unit: row['unit'] as String,
            currentQuantity: (row['current_quantity'] as num).toDouble(),
            reorderLevel: (row['reorder_level'] as num).toDouble(),
            unitCostAmount: row['unit_cost_amount'] as int?,
            isActive: row['is_active'] as bool,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> recordMovement({
    required String itemId,
    required String movementType,
    required double quantityDelta,
    int? unitCostAmount,
    String? note,
  }) => _client.rpc(
    'record_inventory_movement',
    params: {
      'p_inventory_item_id': itemId,
      'p_movement_type': movementType,
      'p_quantity_delta': quantityDelta,
      'p_unit_cost_amount': unitCostAmount,
      'p_note': note,
    },
  );
}
