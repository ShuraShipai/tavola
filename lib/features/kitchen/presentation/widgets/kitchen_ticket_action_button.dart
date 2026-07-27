import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../domain/entities/kitchen_ticket.dart';

class KitchenTicketActionButton extends StatelessWidget {
  const KitchenTicketActionButton({
    required this.status,
    required this.isUpdating,
    required this.onPressed,
    super.key,
  });
  final KitchenTicketStatus status;
  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(status.nextAction);
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: status == KitchenTicketStatus.preparing
          ? FilledButton(
              onPressed: isUpdating ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: TavolaColors.accent,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: isUpdating ? null : onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: child,
            ),
    );
  }
}
