class Reservation {
  const Reservation({
    required this.id,
    required this.restaurantId,
    required this.branchId,
    required this.guestName,
    required this.guestPhone,
    required this.partySize,
    required this.reservedFor,
    required this.status,
    required this.tableLabel,
    this.customerId,
    this.tableId,
    this.notes,
    this.durationMinutes = 90,
    this.sendConfirmationSms = true,
  });

  final String id;
  final String restaurantId;
  final String branchId;
  final String guestName;
  final String? guestPhone;
  final int partySize;
  final DateTime reservedFor;
  final ReservationStatus status;
  final String? tableLabel;
  final String? customerId;
  final String? tableId;
  final String? notes;
  final int durationMinutes;
  final bool sendConfirmationSms;
}

/// A table the database has determined can host a reservation at its time.
/// This deliberately is not the full tables feature entity: eligibility is a
/// reservation-specific, server-authoritative decision.
class ReservationTableCandidate {
  const ReservationTableCandidate({
    required this.id,
    required this.label,
    required this.capacity,
  });

  final String id;
  final String label;
  final int capacity;
}

class ReservationQuery {
  const ReservationQuery({this.branchId, this.statuses, this.from, this.until});

  final String? branchId;
  final Set<ReservationStatus>? statuses;
  final DateTime? from;
  final DateTime? until;
}

enum ReservationStatus {
  pending,
  confirmed,
  seated,
  completed,
  cancelled,
  noShow,
}

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.noShow => 'No show',
    _ => name[0].toUpperCase() + name.substring(1),
  };
}
