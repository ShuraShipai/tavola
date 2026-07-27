import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_staff_repository.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/usecases/get_restaurant_staff.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseStaffRepository(client);
});

final getRestaurantStaffProvider = Provider<GetRestaurantStaff>(
  (ref) => GetRestaurantStaff(ref.watch(staffRepositoryProvider)),
);

final restaurantStaffProvider = FutureProvider<List<StaffMember>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return const [];
  return ref.watch(getRestaurantStaffProvider)(membership.restaurantId);
});
