class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
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
  });

  final String id;
  final String name;
  final String categoryId;
  final int priceMinor;
  final bool isAvailable;
  final String? description;
  final String? foodType;
}

class MenuCatalog {
  const MenuCatalog({required this.categories, required this.items});

  final List<MenuCategory> categories;
  final List<MenuItem> items;
}
