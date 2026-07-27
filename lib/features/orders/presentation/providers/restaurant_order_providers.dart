import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_restaurant_order_repository.dart';
import '../../domain/entities/restaurant_order.dart';
import '../../domain/repositories/restaurant_order_repository.dart';
import '../../domain/usecases/get_restaurant_orders.dart';
import '../../domain/usecases/create_restaurant_order.dart';
import '../../domain/usecases/transition_restaurant_order.dart';
import '../../domain/usecases/update_restaurant_order.dart';
import '../../domain/usecases/watch_restaurant_orders.dart';

final restaurantOrderRepositoryProvider = Provider<RestaurantOrderRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseRestaurantOrderRepository(client);
});

final getRestaurantOrdersProvider = Provider<GetRestaurantOrders>(
  (ref) => GetRestaurantOrders(ref.watch(restaurantOrderRepositoryProvider)),
);

final createRestaurantOrderProvider = Provider<CreateRestaurantOrder>(
  (ref) => CreateRestaurantOrder(ref.watch(restaurantOrderRepositoryProvider)),
);
final updateRestaurantOrderProvider = Provider<UpdateRestaurantOrder>(
  (ref) => UpdateRestaurantOrder(ref.watch(restaurantOrderRepositoryProvider)),
);
final transitionRestaurantOrderProvider = Provider<TransitionRestaurantOrder>(
  (ref) =>
      TransitionRestaurantOrder(ref.watch(restaurantOrderRepositoryProvider)),
);

final restaurantOrdersProvider = StreamProvider<List<RestaurantOrder>>((
  ref,
) async* {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    yield const [];
    return;
  }
  yield* WatchRestaurantOrders(ref.watch(restaurantOrderRepositoryProvider))(
    membership.restaurantId,
  );
});

final orderMutationControllerProvider =
    AsyncNotifierProvider<OrderMutationController, void>(
      OrderMutationController.new,
    );

class OrderMutationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(CreateOrderInput input) =>
      _run(() => ref.read(createRestaurantOrderProvider)(input));

  Future<void> save(UpdateOrderInput input) =>
      _run(() => ref.read(updateRestaurantOrderProvider)(input));

  Future<void> transition({
    required RestaurantOrder order,
    required RestaurantOrderStatus to,
  }) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (membership == null) {
      state = AsyncError(
        StateError('Select a restaurant before changing an order.'),
        StackTrace.current,
      );
      return;
    }
    await _run(
      () => ref.read(transitionRestaurantOrderProvider)(
        restaurantId: membership.restaurantId,
        orderId: order.id,
        from: order.status,
        to: to,
      ),
    );
  }

  Future<void> _run(Future<RestaurantOrder> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await operation();
      ref.invalidate(restaurantOrdersProvider);
    });
  }
}
