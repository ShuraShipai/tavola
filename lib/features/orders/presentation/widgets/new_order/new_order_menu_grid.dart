import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_tokens.dart';
import '../../../../menu/domain/entities/menu_entities.dart';
import 'new_order_menu_card.dart';

/// Responsive card grid for the selectable menu items in a new order.
class NewOrderMenuGrid extends StatelessWidget {
  const NewOrderMenuGrid({
    super.key,
    required this.items,
    required this.quantityForItem,
    required this.onAddItem,
  });

  final List<MenuItem> items;
  final int Function(MenuItem item) quantityForItem;
  final ValueChanged<MenuItem> onAddItem;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 600
          ? 3
          : 2;
      return GridView.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: TavolaSpace.md,
          crossAxisSpacing: TavolaSpace.md,
          childAspectRatio: 1.12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return NewOrderMenuCard(
            item: item,
            quantity: quantityForItem(item),
            onAdd: () => onAddItem(item),
          );
        },
      );
    },
  );
}
