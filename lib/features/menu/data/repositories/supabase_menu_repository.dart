import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/menu_entities.dart';
import '../../domain/repositories/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  SupabaseMenuRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<MenuCatalog> getCatalog(String restaurantId) async {
    final responses = await Future.wait([
      _client
          .from('menu_categories')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('sort_order'),
      _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('name'),
    ]);
    final categories = (responses[0] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_categoryFromRow)
        .toList(growable: false);
    final items = (responses[1] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_itemFromRow)
        .toList(growable: false);
    return MenuCatalog(categories: categories, items: items);
  }

  MenuCategory _categoryFromRow(Map<String, dynamic> row) => MenuCategory(
    id: row['id'].toString(),
    name: row['name'] as String? ?? 'Unnamed category',
    sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    isActive: row['is_active'] as bool? ?? true,
  );
  MenuItem _itemFromRow(Map<String, dynamic> row) => MenuItem(
    id: row['id'].toString(),
    name: row['name'] as String? ?? 'Unnamed item',
    categoryId: row['category_id']?.toString() ?? '',
    priceMinor: (row['price_amount'] as num?)?.toInt() ?? 0,
    isAvailable: row['is_available'] as bool? ?? true,
    description: row['description'] as String?,
    foodType: row['food_type'] as String?,
  );

  @override
  Future<void> saveCategory({
    required String restaurantId,
    String? id,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('menu_categories').insert(row);
    } else {
      await _client.from('menu_categories').update(row).eq('id', id);
    }
  }

  @override
  Future<void> saveItem({
    required String restaurantId,
    String? id,
    required String name,
    String? categoryId,
    String? description,
    required int priceMinor,
    bool isAvailable = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'category_id': categoryId,
      'description': description?.trim(),
      'price_amount': priceMinor,
      'is_available': isAvailable,
    };
    if (id == null) {
      await _client.from('menu_items').insert(row);
    } else {
      await _client.from('menu_items').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteCategory(String id) =>
      _client.from('menu_categories').delete().eq('id', id);
  @override
  Future<void> deleteItem(String id) =>
      _client.from('menu_items').delete().eq('id', id);
}
