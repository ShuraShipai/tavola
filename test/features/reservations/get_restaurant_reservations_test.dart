import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/reservations/domain/entities/reservation.dart';
import 'package:tavola/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:tavola/features/reservations/domain/usecases/get_restaurant_reservations.dart';

void main() {
  test('passes the requested restaurant to reservations repository', () async {
    final repository = _Fake();
    final results = await GetRestaurantReservations(repository)('restaurant-a');
    expect(repository.restaurantId, 'restaurant-a');
    expect(results.single.guestName, 'Arjun Mehta');
  });
}

class _Fake implements ReservationRepository {
  String? restaurantId;
  @override
  Future<List<Reservation>> getReservations(
    String id, {
    ReservationQuery? query,
  }) async {
    restaurantId = id;
    return [
      Reservation(
        id: 'reservation-1',
        restaurantId: id,
        branchId: 'branch-1',
        guestName: 'Arjun Mehta',
        guestPhone: null,
        partySize: 4,
        reservedFor: DateTime.utc(2026, 7, 25),
        status: ReservationStatus.confirmed,
        tableLabel: 'Table 5',
      ),
    ];
  }

  @override
  Future<void> saveReservation({
    required String restaurantId,
    String? id,
    required String? branchId,
    String? customerId,
    String? tableId,
    required String guestName,
    String? guestPhone,
    required int partySize,
    required DateTime reservedFor,
    String? notes,
    int durationMinutes = 90,
    bool sendConfirmationSms = true,
  }) async {}
  @override
  Future<List<ReservationTableCandidate>> getEligibleTables({
    required String restaurantId,
    required String branchId,
    required DateTime reservedFor,
    required int partySize,
    int durationMinutes = 90,
    String? excludeReservationId,
  }) async => const [];
  @override
  Future<void> assignTable({
    required String reservationId,
    required String tableId,
  }) async {}
  @override
  Future<void> seatReservation({
    required String reservationId,
    String? tableId,
  }) async {}
  @override
  Future<void> cancelReservation({required String reservationId}) async {}
  @override
  Future<void> transition({
    required String reservationId,
    required ReservationStatus status,
    String? tableId,
  }) async {}
}
