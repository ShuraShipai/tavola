import '../entities/menu_entities.dart';

abstract interface class MenuRepository {
  Future<MenuCatalog> getCatalog(String restaurantId);
  Future<void> saveCategory({
    required String restaurantId,
    String? id,
    required String name,
    int sortOrder,
    bool isActive,
  });
  Future<void> saveItem({
    required String restaurantId,
    String? id,
    required String name,
    String? categoryId,
    String? description,
    required int priceMinor,
    bool isAvailable,
  });
  Future<void> deleteCategory(String id);
  Future<void> deleteItem(String id);
}
