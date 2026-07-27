import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_dashboard_repository.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_snapshot.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not configured.');
  }
  return SupabaseDashboardRepository(client);
});
final getDashboardSnapshotProvider = Provider(
  (ref) => GetDashboardSnapshot(ref.watch(dashboardRepositoryProvider)),
);
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((
  ref,
) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    throw StateError('Choose a restaurant before loading the dashboard.');
  }
  return ref.watch(getDashboardSnapshotProvider)(
    membership.restaurantId,
    DateTime.now(),
  );
});
