import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';
import '../../../../../core/formatters/app_formatters.dart';
import '../../../domain/entities/restaurant_order.dart';
import 'quantity_stepper.dart';

/// One editable order line in the new-order ticket.
class OrderTicketLine extends StatelessWidget {
  const OrderTicketLine({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
  });

  final OrderLine line;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TavolaSpace.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TavolaColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (line.notes?.isNotEmpty == true) ...[
                const SizedBox(height: TavolaSpace.xxs),
                Text(
                  line.notes!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TavolaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: TavolaSpace.xs),
        QuantityStepper(
          quantity: line.quantity.toInt(),
          onIncrement: onIncrement,
          onDecrement: onDecrement,
          enabled: enabled,
        ),
        const SizedBox(width: TavolaSpace.xs),
        SizedBox(
          width: 54,
          child: Text(
            AppFormatters.currency.format(line.lineTotalAmount / 100),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: TavolaColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
