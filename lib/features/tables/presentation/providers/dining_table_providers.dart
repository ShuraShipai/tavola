import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_dining_table_repository.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/repositories/dining_table_repository.dart';
import '../../domain/usecases/create_dining_table.dart';
import '../../domain/usecases/get_restaurant_tables.dart';
import '../../domain/usecases/update_dining_table_status.dart';
import '../../domain/usecases/watch_restaurant_tables.dart';

final diningTableRepositoryProvider = Provider<DiningTableRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseDiningTableRepository(client);
});

final getRestaurantTablesProvider = Provider<GetRestaurantTables>(
  (ref) => GetRestaurantTables(ref.watch(diningTableRepositoryProvider)),
);

final createDiningTableProvider = Provider<CreateDiningTable>(
  (ref) => CreateDiningTable(ref.watch(diningTableRepositoryProvider)),
);

final deleteDiningTableProvider = Provider<Future<void> Function(String)>(
  (ref) =>
      (tableId) =>
          ref.read(diningTableRepositoryProvider).deleteTable(tableId: tableId),
);

final restaurantTablesProvider = StreamProvider<List<DiningTable>>((
  ref,
) async* {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    yield const [];
    return;
  }
  yield* WatchRestaurantTables(ref.watch(diningTableRepositoryProvider))(
    membership.restaurantId,
  );
});

final updateDiningTableStatusProvider = Provider<UpdateDiningTableStatus>(
  (ref) => UpdateDiningTableStatus(ref.watch(diningTableRepositoryProvider)),
);

final tableStatusControllerProvider =
    AsyncNotifierProvider<TableStatusController, void>(
      TableStatusController.new,
    );

class TableStatusController extends AsyncNotifier<void> {
  Future<void> seat(DiningTable table) => _run(
    () => ref
        .read(diningTableRepositoryProvider)
        .seatTable(tableId: table.id, expectedVersion: table.version),
  );

  Future<void> assignOrder({
    required DiningTable table,
    required String orderId,
  }) => _run(
    () => ref
        .read(diningTableRepositoryProvider)
        .assignOrder(
          orderId: orderId,
          tableId: table.id,
          expectedTableVersion: table.version,
        ),
  );

  Future<void> merge({
    required DiningTable primaryTable,
    required List<DiningTable> secondaryTables,
  }) => _run(
    () => ref
        .read(diningTableRepositoryProvider)
        .mergeTables(
          primaryTableId: primaryTable.id,
          secondaryTableIds: secondaryTables.map((table) => table.id).toList(),
        ),
  );

  Future<void> updateStatus({
    required String tableId,
    required DiningTableStatus status,
    String? currentStatusDetail,
  }) async {
    final membership = await ref.read(currentMembershipProvider.future);
    if (membership == null) {
      state = AsyncError(
        StateError('Select a restaurant before changing a table status.'),
        StackTrace.current,
      );
      return;
    }
    await _run(() async {
      await ref.read(updateDiningTableStatusProvider)(
        restaurantId: membership.restaurantId,
        tableId: tableId,
        status: status,
        currentStatusDetail: currentStatusDetail,
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      ref.invalidate(restaurantTablesProvider);
    });
  }

  @override
  Future<void> build() async {}
}
