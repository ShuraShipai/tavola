import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_billing_repository.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/usecases/collect_payment.dart';
import '../../domain/usecases/watch_bills.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseBillingRepository(client);
});
final billsProvider = StreamProvider<List<Bill>>((ref) async* {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    yield const [];
    return;
  }
  yield* WatchBills(ref.watch(billingRepositoryProvider))(
    membership.restaurantId,
  );
});
final billingMutationProvider = AsyncNotifierProvider<BillingMutation, void>(
  BillingMutation.new,
);

class BillingMutation extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}
  Future<void> collect({
    required Bill bill,
    required PaymentMethod method,
    int? amount,
    String? externalReference,
  }) async {
    final collectedAmount = amount ?? bill.amountDue;
    if (collectedAmount <= 0 || collectedAmount > bill.amountDue) {
      state = AsyncError(
        ArgumentError.value(
          collectedAmount,
          'amount',
          'must be between 1 and the remaining balance',
        ),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await CollectPayment(ref.read(billingRepositoryProvider))(
        orderId: bill.orderId,
        method: method,
        amount: collectedAmount,
        externalReference: externalReference,
      );
      ref.invalidate(billsProvider);
    });
  }
}
