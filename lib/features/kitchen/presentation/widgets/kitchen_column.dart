import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/kitchen_ticket.dart';
import 'kitchen_column_count.dart';
import 'kitchen_ticket_card.dart';

class KitchenColumn extends StatelessWidget {
  const KitchenColumn({
    required this.status,
    required this.tickets,
    required this.isUpdating,
    required this.onAdvance,
    super.key,
  });
  final KitchenTicketStatus status;
  final List<KitchenTicket> tickets;
  final bool isUpdating;
  final ValueChanged<KitchenTicket> onAdvance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              status.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .48,
                color: TavolaColors.textSecondary,
              ),
            ),
          ),
          KitchenColumnCount(count: tickets.length),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      for (final ticket in tickets)
        KitchenTicketCard(
          ticket: ticket,
          isUpdating: isUpdating,
          onAdvance: () => onAdvance(ticket),
        ),
    ],
  );
}
