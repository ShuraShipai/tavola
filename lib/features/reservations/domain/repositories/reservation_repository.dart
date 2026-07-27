import '../entities/reservation.dart';

abstract interface class ReservationRepository {
  Future<List<Reservation>> getReservations(
    String restaurantId, {
    ReservationQuery? query,
  });
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
  });
  Future<List<ReservationTableCandidate>> getEligibleTables({
    required String restaurantId,
    required String branchId,
    required DateTime reservedFor,
    required int partySize,
    int durationMinutes = 90,
    String? excludeReservationId,
  });
  Future<void> assignTable({
    required String reservationId,
    required String tableId,
  });
  Future<void> seatReservation({
    required String reservationId,
    String? tableId,
  });
  Future<void> cancelReservation({required String reservationId});
  Future<void> transition({
    required String reservationId,
    required ReservationStatus status,
    String? tableId,
  });
}
