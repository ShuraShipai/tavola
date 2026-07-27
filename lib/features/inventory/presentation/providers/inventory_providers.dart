import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_inventory_repository.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/usecases/get_inventory_items.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseInventoryRepository(client);
});
final getInventoryItemsProvider = Provider<GetInventoryItems>(
  (ref) => GetInventoryItems(ref.watch(inventoryRepositoryProvider)),
);
final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return const [];
  return ref.watch(getInventoryItemsProvider)(membership.restaurantId);
});
