import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_discount_repository.dart';
import '../../domain/entities/discount_entities.dart';
import '../../domain/repositories/discount_repository.dart';
import '../../domain/usecases/get_discount_catalog.dart';

final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseDiscountRepository(client);
});
final getDiscountCatalogProvider = Provider(
  (ref) => GetDiscountCatalog(ref.watch(discountRepositoryProvider)),
);
final discountCatalogProvider = FutureProvider<DiscountCatalog>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    throw StateError('Choose a restaurant before loading discounts.');
  }
  return ref.watch(getDiscountCatalogProvider)(membership.restaurantId);
});
