import 'package:flutter/material.dart';

import '../../../../../core/design/tavola_colors.dart';
import '../../../../../core/design/tavola_tokens.dart';

/// Compact increment/decrement control used in an order ticket.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _StepButton(
        icon: Icons.remove,
        tooltip: 'Decrease quantity',
        onPressed: enabled && quantity > 0 ? onDecrement : null,
      ),
      SizedBox(
        width: 28,
        child: Text(
          '$quantity',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TavolaColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      _StepButton(
        icon: Icons.add,
        tooltip: 'Increase quantity',
        onPressed: enabled ? onIncrement : null,
      ),
    ],
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox.square(
      dimension: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(28),
          side: const BorderSide(color: TavolaColors.border),
          shape: const RoundedRectangleBorder(borderRadius: TavolaRadius.small),
        ),
        child: Icon(icon, size: TavolaSize.iconSmall),
      ),
    ),
  );
}
