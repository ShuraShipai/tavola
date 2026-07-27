class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    this.description,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final String? description;
  final int itemCount;

  /// Inactive categories must not be offered to new orders.
  bool get isOrderable => isActive;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.priceMinor,
    required this.isAvailable,
    this.description,
    this.foodType,
    this.imagePath,
    this.imageStoragePath,
    this.taxRateBasisPoints = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.tracksStock = false,
    this.isChefRecommended = false,
  });

  final String id;
  final String name;
  final String categoryId;
  final int priceMinor;
  final bool isAvailable;
  final String? description;
  final String? foodType;

  /// A short-lived signed URL or an external image URL for display only.
  final String? imagePath;

  /// The private Storage object key. Use this when persisting an unchanged image.
  final String? imageStoragePath;
  final int taxRateBasisPoints;
  final bool isActive;
  final int sortOrder;
  final bool tracksStock;
  final bool isChefRecommended;

  /// Both an active item and its availability switch must allow ordering.
  bool get isOrderable => isActive && isAvailable;
}

class MenuCatalog {
  const MenuCatalog({required this.categories, required this.items});

  final List<MenuCategory> categories;
  final List<MenuItem> items;
}
