import 'package:flutter/material.dart';

import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/kitchen_ticket.dart';
import 'kitchen_ticket_action_button.dart';

class KitchenTicketCard extends StatelessWidget {
  const KitchenTicketCard({
    required this.ticket,
    required this.isUpdating,
    required this.onAdvance,
    super.key,
  });
  final KitchenTicket ticket;
  final bool isUpdating;
  final VoidCallback onAdvance;

  Color get _tone => switch (ticket.status) {
    KitchenTicketStatus.queued => TavolaColors.info,
    KitchenTicketStatus.preparing => TavolaColors.accent,
    KitchenTicketStatus.ready => TavolaColors.success,
    KitchenTicketStatus.served ||
    KitchenTicketStatus.cancelled => TavolaColors.borderStrong,
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: TavolaSpace.md),
    padding: const EdgeInsets.all(TavolaSpace.md),
    decoration: BoxDecoration(
      color: TavolaColors.surface,
      borderRadius: TavolaRadius.medium,
      border: Border(
        top: const BorderSide(color: TavolaColors.border),
        right: const BorderSide(color: TavolaColors.border),
        bottom: const BorderSide(color: TavolaColors.border),
        left: BorderSide(color: _tone, width: 4),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.tableLabel ??
                    '${ticket.orderType} #${ticket.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _elapsed(ticket.createdAt, ticket.status),
              style: const TextStyle(
                fontSize: 12,
                color: TavolaColors.textMuted,
              ),
            ),
          ],
        ),
        for (final item in ticket.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '${_quantity(item.quantity)}× ${item.name}${_itemNote(item.notes)}',
              style: const TextStyle(height: 1.35),
            ),
          ),
        if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
          const SizedBox(height: TavolaSpace.xs),
          Text(
            'Note: ${ticket.notes}',
            style: const TextStyle(color: TavolaColors.textSecondary),
          ),
        ],
        const SizedBox(height: TavolaSpace.md),
        KitchenTicketActionButton(
          status: ticket.status,
          isUpdating: isUpdating,
          onPressed: onAdvance,
        ),
      ],
    ),
  );

  String _elapsed(DateTime createdAt, KitchenTicketStatus status) {
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    if (minutes <= 0) return 'Just now';
    if (status == KitchenTicketStatus.ready) return 'Ready $minutes min';
    return '$minutes min';
  }

  String _quantity(num quantity) => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
  String _itemNote(String? note) =>
      note == null || note.isEmpty ? '' : ' · $note';
}
