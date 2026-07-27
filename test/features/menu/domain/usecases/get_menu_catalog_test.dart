import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/menu/domain/entities/menu_entities.dart';
import 'package:tavola/features/menu/domain/repositories/menu_repository.dart';
import 'package:tavola/features/menu/domain/usecases/get_menu_catalog.dart';

void main() {
  test('gets the catalogue for the current restaurant id', () async {
    final repository = _MenuRepository();
    final result = await GetMenuCatalog(repository)('restaurant-1');
    expect(repository.restaurantId, 'restaurant-1');
    expect(result.items.single.name, 'Margherita');
  });
}

class _MenuRepository implements MenuRepository {
  String? restaurantId;
  @override
  Future<MenuCatalog> getCatalog(String id) async {
    restaurantId = id;
    return const MenuCatalog(
      categories: [],
      items: [
        MenuItem(
          id: 'item-1',
          name: 'Margherita',
          categoryId: '',
          priceMinor: 34000,
          isAvailable: true,
        ),
      ],
    );
  }

  @override
  Future<void> deleteCategory(
    String id, {
    String? moveItemsToCategoryId,
  }) async {}
  @override
  Future<void> deleteItem(String id) async {}
  @override
  Future<void> saveCategory({
    required String restaurantId,
    String? id,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
    String? description,
  }) async {}
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
  }) async {}
  @override
  Future<String> uploadItemImage({
    required String restaurantId,
    required Uint8List bytes,
    required String extension,
  }) async => '';
}
