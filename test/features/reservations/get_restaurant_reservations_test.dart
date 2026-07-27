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
  Future<List<Reservation>> getReservations(String id) async {
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
    required String branchId,
    String? customerId,
    String? tableId,
    required String guestName,
    String? guestPhone,
    required int partySize,
    required DateTime reservedFor,
    String? notes,
  }) async {}
  @override
  Future<void> transition({
    required String reservationId,
    required ReservationStatus status,
    String? tableId,
  }) async {}
}
