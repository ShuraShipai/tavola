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
