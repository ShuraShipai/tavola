import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/get_restaurant_customers.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseCustomerRepository(client);
});

final getRestaurantCustomersProvider = Provider<GetRestaurantCustomers>(
  (ref) => GetRestaurantCustomers(ref.watch(customerRepositoryProvider)),
);

final restaurantCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return const [];
  return ref.watch(getRestaurantCustomersProvider)(membership.restaurantId);
});
