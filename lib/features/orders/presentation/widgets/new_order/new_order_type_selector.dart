import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';
import '../../../domain/entities/restaurant_order.dart';

/// Segmented order-type selector styled for the order composer workspace.
class NewOrderTypeSelector extends StatelessWidget {
  const NewOrderTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RestaurantOrderType value;
  final ValueChanged<RestaurantOrderType> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Order type',
    child: Container(
      height: TavolaSize.buttonHeight,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: TavolaColors.surfaceVariant,
        borderRadius: TavolaRadius.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: RestaurantOrderType.values
            .map(
              (type) => _OrderTypeButton(
                type: type,
                selected: type == value,
                onPressed: () => onChanged(type),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _OrderTypeButton extends StatelessWidget {
  const _OrderTypeButton({
    required this.type,
    required this.selected,
    required this.onPressed,
  });

  final RestaurantOrderType type;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: type.label,
    child: TextButton(
      onPressed: onPressed,
      style:
          TextButton.styleFrom(
            foregroundColor: selected
                ? TavolaColors.textPrimary
                : TavolaColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: TavolaSpace.md),
            minimumSize: const Size(0, TavolaSize.buttonHeight - 6),
            shape: const RoundedRectangleBorder(
              borderRadius: TavolaRadius.small,
            ),
            backgroundColor: selected
                ? TavolaColors.surface
                : Colors.transparent,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            elevation: WidgetStatePropertyAll(selected ? 1 : 0),
            shadowColor: const WidgetStatePropertyAll(TavolaColors.shadow),
          ),
      child: Text(type.label),
    ),
  );
}
