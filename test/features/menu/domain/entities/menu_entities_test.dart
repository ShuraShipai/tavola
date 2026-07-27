import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/menu/domain/entities/menu_entities.dart';

void main() {
  test('an item is orderable only when it is active and available', () {
    const unavailable = MenuItem(
      id: 'item-1',
      name: 'Coffee',
      categoryId: 'drinks',
      priceMinor: 20000,
      isAvailable: false,
    );
    const inactive = MenuItem(
      id: 'item-2',
      name: 'Iced coffee',
      categoryId: 'drinks',
      priceMinor: 22000,
      isAvailable: true,
      isActive: false,
    );
    const ready = MenuItem(
      id: 'item-3',
      name: 'Espresso',
      categoryId: 'drinks',
      priceMinor: 18000,
      isAvailable: true,
    );

    expect(unavailable.isOrderable, isFalse);
    expect(inactive.isOrderable, isFalse);
    expect(ready.isOrderable, isTrue);
  });

  test('a category is orderable only while active', () {
    const active = MenuCategory(
      id: 'drinks',
      name: 'Drinks',
      sortOrder: 1,
      isActive: true,
    );
    const inactive = MenuCategory(
      id: 'seasonal',
      name: 'Seasonal',
      sortOrder: 2,
      isActive: false,
    );

    expect(active.isOrderable, isTrue);
    expect(inactive.isOrderable, isFalse);
  });
}
