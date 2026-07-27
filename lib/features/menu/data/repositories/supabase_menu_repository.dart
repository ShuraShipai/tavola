import 'dart:typed_data';

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
          .order('sort_order')
          .order('created_at'),
      _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('name'),
    ]);
    final items = await Future.wait(
      (responses[1] as List<dynamic>).cast<Map<String, dynamic>>().map(
        _itemFromRow,
      ),
    );
    final itemCounts = <String, int>{};
    for (final item in items) {
      if (item.categoryId.isNotEmpty) {
        itemCounts.update(
          item.categoryId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final categories =
        (responses[0] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(
              (row) => _categoryFromRow(
                row,
                itemCount: itemCounts[row['id'].toString()] ?? 0,
              ),
            )
            .toList()
          ..sort((left, right) {
            final byOrder = left.sortOrder.compareTo(right.sortOrder);
            return byOrder != 0 ? byOrder : left.name.compareTo(right.name);
          });
    return MenuCatalog(categories: categories, items: items);
  }

  MenuCategory _categoryFromRow(
    Map<String, dynamic> row, {
    int itemCount = 0,
  }) => MenuCategory(
    id: row['id'].toString(),
    name: row['name'] as String? ?? 'Unnamed category',
    sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
    isActive: row['is_active'] as bool? ?? true,
    description: row['description'] as String?,
    itemCount: itemCount,
  );
  Future<MenuItem> _itemFromRow(Map<String, dynamic> row) async {
    final storedPath = row['image_path'] as String?;
    return MenuItem(
      id: row['id'].toString(),
      name: row['name'] as String? ?? 'Unnamed item',
      categoryId: row['category_id']?.toString() ?? '',
      priceMinor: (row['price_amount'] as num?)?.toInt() ?? 0,
      isAvailable: row['is_available'] as bool? ?? true,
      description: row['description'] as String?,
      foodType: row['food_type'] as String?,
      imagePath: await _displayImageUrl(storedPath),
      imageStoragePath: storedPath,
      taxRateBasisPoints: (row['tax_rate_basis_points'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      tracksStock: row['tracks_stock'] as bool? ?? false,
      isChefRecommended: row['is_chef_recommended'] as bool? ?? false,
    );
  }

  @override
  Future<void> saveCategory({
    required String restaurantId,
    String? id,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
    String? description,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
      'description': _nullableText(description),
    };
    if (id == null) {
      await _client.from('menu_categories').insert(row);
    } else {
      await _client.from('menu_categories').update(row).eq('id', id);
    }
  }

  @override
  Future<String> uploadItemImage({
    required String restaurantId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeExtension = switch (extension.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      'gif' => 'gif',
      _ => 'jpg',
    };
    final path =
        '$restaurantId/menu-items/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    await _client.storage
        .from('restaurant-assets')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$safeExtension',
            upsert: false,
          ),
        );
    return path;
  }

  Future<String?> _displayImageUrl(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) return storedPath;
    if (Uri.tryParse(storedPath)?.hasScheme ?? false) return storedPath;
    return _client.storage
        .from('restaurant-assets')
        .createSignedUrl(storedPath, 60 * 60);
  }

  @override
  Future<void> saveItem({
    required String restaurantId,
    String? id,
    required String name,
    String? categoryId,
    String? description,
    String? imagePath,
    required int priceMinor,
    bool isAvailable = true,
    String? foodType,
    int taxRateBasisPoints = 0,
    bool isActive = true,
    int sortOrder = 0,
    bool tracksStock = false,
    bool isChefRecommended = false,
  }) async {
    if (priceMinor < 0) throw ArgumentError.value(priceMinor, 'priceMinor');
    if (taxRateBasisPoints < 0 || taxRateBasisPoints > 10000) {
      throw ArgumentError.value(taxRateBasisPoints, 'taxRateBasisPoints');
    }
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'category_id': categoryId,
      'description': _nullableText(description),
      'price_amount': priceMinor,
      'is_available': isAvailable,
      'food_type': _nullableText(foodType),
      'tax_rate_basis_points': taxRateBasisPoints,
      'is_active': isActive,
      'sort_order': sortOrder,
      'tracks_stock': tracksStock,
      'is_chef_recommended': isChefRecommended,
    };
    // An editor that does not replace the image must not accidentally clear
    // the existing private object key. Image removal can be added later as an
    // explicit, separately-confirmed operation.
    if (id == null || imagePath != null) {
      row['image_path'] = _nullableText(imagePath);
    }
    if (id == null) {
      await _client.from('menu_items').insert(row);
    } else {
      final existing = imagePath == null
          ? null
          : await _client
                .from('menu_items')
                .select('image_path')
                .eq('id', id)
                .maybeSingle();
      await _client.from('menu_items').update(row).eq('id', id);
      await _removeImageIfReplaced(
        existing?['image_path'] as String?,
        imagePath,
      );
    }
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _removeImageIfReplaced(String? oldPath, String? newPath) async {
    if (oldPath == null || oldPath.trim().isEmpty || oldPath == newPath) return;
    if (Uri.tryParse(oldPath)?.hasScheme ?? false) return;
    try {
      await _client.storage.from('restaurant-assets').remove([oldPath]);
    } catch (_) {
      // The menu update succeeded. Storage cleanup can be retried separately.
    }
  }

  @override
  Future<void> deleteCategory(String id, {String? moveItemsToCategoryId}) =>
      _client.rpc(
        'delete_menu_category',
        params: {
          'p_category_id': id,
          'p_destination_category_id': moveItemsToCategoryId,
        },
      );
  @override
  Future<void> deleteItem(String id) async {
    final row = await _client
        .from('menu_items')
        .select('image_path')
        .eq('id', id)
        .maybeSingle();
    await _client.from('menu_items').delete().eq('id', id);

    final imagePath = row?['image_path'] as String?;
    if (imagePath == null || imagePath.trim().isEmpty) return;
    if (Uri.tryParse(imagePath)?.hasScheme ?? false) return;
    try {
      await _client.storage.from('restaurant-assets').remove([imagePath]);
    } catch (_) {
      // The menu record has already been deleted. A failed storage cleanup must
      // not turn a successful delete into an apparent failure for the user.
    }
  }
}
