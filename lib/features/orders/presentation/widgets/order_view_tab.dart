import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';

/// A visual order-view selector. Selection state remains with OrdersPage.
class OrderViewTab extends StatelessWidget {
  const OrderViewTab({required this.label, this.selected = false, super.key});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected ? TavolaColors.primary : TavolaColors.surface,
      border: Border.all(
        color: selected ? TavolaColors.primary : TavolaColors.border,
      ),
      borderRadius: TavolaRadius.extraLarge,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TavolaSpace.md,
        vertical: TavolaSpace.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected
              ? TavolaColors.textInverse
              : TavolaColors.textSecondary,
        ),
      ),
    ),
  );
}
