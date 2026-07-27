import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tavola_tokens.dart';
import '../../../../core/widgets/tavola_app_shell.dart';
import '../../../../core/widgets/tavola_states.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/kitchen_ticket_providers.dart';
import '../widgets/kitchen_action_error.dart';
import '../widgets/kitchen_board.dart';
import '../widgets/kitchen_top_bar.dart';

class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(kitchenTicketsProvider);
    final action = ref.watch(kitchenTicketActionProvider);
    return TavolaAppShell(
      activeRoute: '/kitchen',
      topBar: KitchenTopBar(activeTicketCount: tickets.dataOrNull?.length),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavolaSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (action.hasError) ...[
              const KitchenActionError(
                message: 'Ticket update failed. Please try again.',
              ),
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
                  : KitchenBoard(
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
