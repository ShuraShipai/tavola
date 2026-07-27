import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_menu_repository.dart';
import '../../domain/entities/menu_entities.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/usecases/get_menu_catalog.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseMenuRepository(client);
});
final getMenuCatalogProvider = Provider(
  (ref) => GetMenuCatalog(ref.watch(menuRepositoryProvider)),
);
final menuCatalogProvider = FutureProvider<MenuCatalog>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    throw StateError('Choose a restaurant before loading the menu.');
  }
  return ref.watch(getMenuCatalogProvider)(membership.restaurantId);
});
