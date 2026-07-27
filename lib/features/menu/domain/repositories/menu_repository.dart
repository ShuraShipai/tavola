import 'dart:typed_data';

import '../entities/menu_entities.dart';

abstract interface class MenuRepository {
  Future<MenuCatalog> getCatalog(String restaurantId);
  Future<void> saveCategory({
    required String restaurantId,
    String? id,
    required String name,
    int sortOrder,
    bool isActive,
    String? description,
  });
  Future<void> saveItem({
    required String restaurantId,
    String? id,
    required String name,
    String? categoryId,
    String? description,
    String? imagePath,
    required int priceMinor,
    bool isAvailable,
    String? foodType,
    int taxRateBasisPoints,
    bool isActive,
    int sortOrder,
    bool tracksStock,
    bool isChefRecommended,
  });
  Future<String> uploadItemImage({
    required String restaurantId,
    required Uint8List bytes,
    required String extension,
  });

  /// Reassigns the category's items before deletion. A null destination means
  /// move them to Uncategorised.
  Future<void> deleteCategory(String id, {String? moveItemsToCategoryId});
  Future<void> deleteItem(String id);
}
