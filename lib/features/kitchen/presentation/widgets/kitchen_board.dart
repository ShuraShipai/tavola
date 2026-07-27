import 'package:flutter/material.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../domain/entities/kitchen_ticket.dart';
import 'kitchen_column.dart';

class KitchenBoard extends StatelessWidget {
  const KitchenBoard({
    required this.tickets,
    required this.isUpdating,
    required this.onAdvance,
    super.key,
  });
  final List<KitchenTicket> tickets;
  final bool isUpdating;
  final ValueChanged<KitchenTicket> onAdvance;

  @override
  Widget build(BuildContext context) {
    const columns = [
      KitchenTicketStatus.queued,
      KitchenTicketStatus.preparing,
      KitchenTicketStatus.ready,
    ];
    final children = columns
        .map(
          (status) => KitchenColumn(
            status: status,
            tickets: tickets
                .where((ticket) => ticket.status == status)
                .toList(),
            isUpdating: isUpdating,
            onAdvance: onAdvance,
          ),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= TavolaBreakpoints.medium
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  Expanded(child: children[i]),
                  if (i < children.length - 1)
                    const SizedBox(width: TavolaSpace.lg),
                ],
              ],
            )
          : Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const SizedBox(height: TavolaSpace.lg),
                ],
              ],
            ),
    );
  }
}
