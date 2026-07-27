import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_reservation_repository.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/usecases/get_restaurant_reservations.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseReservationRepository(client);
});
final getRestaurantReservationsProvider = Provider<GetRestaurantReservations>(
  (ref) => GetRestaurantReservations(ref.watch(reservationRepositoryProvider)),
);
final restaurantReservationsProvider = FutureProvider<List<Reservation>>((
  ref,
) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return const [];
  return ref.watch(getRestaurantReservationsProvider)(membership.restaurantId);
});
