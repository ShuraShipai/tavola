import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_breakpoints.dart';
import '../../../../core/design/tavola_colors.dart';
import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../../core/widgets/tavola_ui_components.dart';
import '../../domain/entities/kitchen_ticket.dart';
import '../providers/kitchen_ticket_providers.dart';

class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(kitchenTicketsProvider);
    final action = ref.watch(kitchenTicketActionProvider);
    return TavolaAppShell(
      activeRoute: '/kitchen',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TavolaPageHeader(
              title: 'Kitchen display',
              subtitle: tickets.when(
                data: (data) =>
                    '${data.length} active tickets · live updates on',
                loading: () => 'Connecting to live kitchen updates…',
                error: (_, _) => 'Kitchen updates are unavailable',
              ),
            ),
            const SizedBox(height: TavolaSpace.lg),
            if (action.hasError) ...[
              _ActionError(message: 'Ticket update failed. Please try again.'),
              const SizedBox(height: TavolaSpace.md),
            ],
            tickets.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(TavolaSpace.xl),
                child: TavolaLoadingIndicator(
                  label: 'Loading kitchen tickets…',
                ),
              ),
              error: (_, _) => TavolaErrorState(
                message: 'We could not load the kitchen queue.',
                onRetry: () => ref.invalidate(kitchenTicketsProvider),
              ),
              data: (data) => data.isEmpty
                  ? const TavolaEmptyState(
                      title: 'Kitchen is clear',
                      message: 'Tickets sent from the POS will appear here.',
                      icon: Icons.soup_kitchen_outlined,
                    )
                  : _KitchenBoard(
                      tickets: data,
                      isUpdating: action.isLoading,
                      onAdvance: (ticket) => ref
                          .read(kitchenTicketActionProvider.notifier)
                          .advance(ticket),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenBoard extends StatelessWidget {
  const _KitchenBoard({
    required this.tickets,
    required this.isUpdating,
    required this.onAdvance,
  });
  final List<KitchenTicket> tickets;
  final bool isUpdating;
  final ValueChanged<KitchenTicket> onAdvance;

  @override
  Widget build(BuildContext context) {
    final columns = [
      (KitchenTicketStatus.queued, TavolaColors.info),
      (KitchenTicketStatus.preparing, TavolaColors.warning),
      (KitchenTicketStatus.ready, TavolaColors.success),
    ];
    final children = columns
        .map(
          (column) => _KitchenColumn(
            status: column.$1,
            color: column.$2,
            tickets: tickets
                .where((ticket) => ticket.status == column.$1)
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
                    const SizedBox(width: TavolaSpace.md),
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

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.status,
    required this.color,
    required this.tickets,
    required this.isUpdating,
    required this.onAdvance,
  });
  final KitchenTicketStatus status;
  final Color color;
  final List<KitchenTicket> tickets;
  final bool isUpdating;
  final ValueChanged<KitchenTicket> onAdvance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            status.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: TavolaSpace.xs),
          TavolaStatusBadge(label: '${tickets.length}', color: color),
        ],
      ),
      const SizedBox(height: TavolaSpace.md),
      if (tickets.isEmpty)
        const TavolaPanel(
          child: Text(
            'No tickets',
            style: TextStyle(color: TavolaColors.textMuted),
          ),
        ),
      for (final ticket in tickets)
        Padding(
          padding: const EdgeInsets.only(bottom: TavolaSpace.md),
          child: _KitchenTicketCard(
            ticket: ticket,
            isUpdating: isUpdating,
            onAdvance: () => onAdvance(ticket),
          ),
        ),
    ],
  );
}

class _KitchenTicketCard extends StatelessWidget {
  const _KitchenTicketCard({
    required this.ticket,
    required this.isUpdating,
    required this.onAdvance,
  });
  final KitchenTicket ticket;
  final bool isUpdating;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) => TavolaPanel(
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
              _elapsed(ticket.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: TavolaColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: TavolaSpace.xxs),
        Text(
          'KOT #${ticket.orderNumber} · ${ticket.orderType.replaceAll('_', ' ')}',
          style: const TextStyle(fontSize: 12, color: TavolaColors.textMuted),
        ),
        const Divider(height: TavolaSpace.lg),
        for (final item in ticket.items)
          Padding(
            padding: const EdgeInsets.only(bottom: TavolaSpace.xs),
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
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isUpdating ? null : onAdvance,
            child: Text(ticket.status.nextAction),
          ),
        ),
      ],
    ),
  );

  String _elapsed(DateTime createdAt) {
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    return minutes <= 0 ? 'Just now' : '${minutes}m';
  }

  String _quantity(num quantity) => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
  String _itemNote(String? note) =>
      note == null || note.isEmpty ? '' : ' · $note';
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: TavolaColors.error.withValues(alpha: 0.1),
        borderRadius: TavolaRadius.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TavolaSpace.sm),
        child: Text(message, style: const TextStyle(color: TavolaColors.error)),
      ),
    ),
  );
}
