import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';
import '../../../../menu/domain/entities/menu_entities.dart';

/// Horizontally scrollable menu category pills for a new order.
class MenuCategoryTabs extends StatelessWidget {
  const MenuCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: TavolaSize.buttonHeight,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: TavolaSpace.xs),
      itemBuilder: (context, index) {
        final category = categories[index];
        final selected = category.id == selectedCategoryId;
        return Semantics(
          button: true,
          selected: selected,
          label: '${category.name} category',
          child: OutlinedButton(
            onPressed: () => onSelected(category.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: selected
                  ? TavolaColors.textInverse
                  : TavolaColors.textSecondary,
              backgroundColor: selected
                  ? TavolaColors.primary
                  : TavolaColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.md),
              side: BorderSide(
                color: selected ? TavolaColors.primary : TavolaColors.border,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: TavolaRadius.extraLarge,
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(category.name),
          ),
        );
      },
    ),
  );
}
