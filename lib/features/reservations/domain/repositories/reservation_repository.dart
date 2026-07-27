import '../entities/reservation.dart';

abstract interface class ReservationRepository {
  Future<List<Reservation>> getReservations(String restaurantId);
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
  });
  Future<void> transition({
    required String reservationId,
    required ReservationStatus status,
    String? tableId,
  });
}
