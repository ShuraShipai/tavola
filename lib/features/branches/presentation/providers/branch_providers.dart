import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_branch_repository.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../../domain/usecases/get_restaurant_branches.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseBranchRepository(client);
});

final getRestaurantBranchesProvider = Provider<GetRestaurantBranches>(
  (ref) => GetRestaurantBranches(ref.watch(branchRepositoryProvider)),
);

final restaurantBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return const [];
  return ref
      .watch(getRestaurantBranchesProvider)(membership.restaurantId)
      .timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'Branch setup timed out. Check the connection and try again.',
        ),
      );
});
