import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_kitchen_ticket_repository.dart';
import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_ticket_repository.dart';
import '../../domain/usecases/update_kitchen_ticket_status.dart';
import '../../domain/usecases/watch_kitchen_tickets.dart';

final kitchenTicketRepositoryProvider = Provider<KitchenTicketRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseKitchenTicketRepository(client);
});

final watchKitchenTicketsProvider = Provider<WatchKitchenTickets>(
  (ref) => WatchKitchenTickets(ref.watch(kitchenTicketRepositoryProvider)),
);

final updateKitchenTicketStatusProvider = Provider<UpdateKitchenTicketStatus>(
  (ref) =>
      UpdateKitchenTicketStatus(ref.watch(kitchenTicketRepositoryProvider)),
);

final kitchenTicketsProvider = StreamProvider<List<KitchenTicket>>((
  ref,
) async* {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    yield const [];
    return;
  }
  yield* ref.watch(watchKitchenTicketsProvider)(membership.restaurantId);
});

final kitchenTicketActionProvider =
    AsyncNotifierProvider<KitchenTicketActionController, void>(
      KitchenTicketActionController.new,
    );

class KitchenTicketActionController extends AsyncNotifier<void> {
  Future<void> advance(KitchenTicket ticket) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(updateKitchenTicketStatusProvider)(
            ticketId: ticket.id,
            currentStatus: ticket.status,
          )
          .then((_) => ref.invalidate(kitchenTicketsProvider)),
    );
  }

  @override
  Future<void> build() async {}
}
