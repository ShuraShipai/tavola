class DiningTable {
  const DiningTable({
    required this.id,
    required this.restaurantId,
    required this.branchId,
    required this.label,
    required this.capacity,
    required this.status,
    required this.sortOrder,
    this.version = 1,
    this.currentStatusDetail,
  });

  final String id;
  final String restaurantId;
  final String branchId;
  final String label;
  final int capacity;
  final DiningTableStatus status;
  final int sortOrder;
  final int version;
  final String? currentStatusDetail;
}

enum DiningTableStatus { available, occupied, reserved, unavailable }

extension DiningTableStatusX on DiningTableStatus {
  String get label => switch (this) {
    DiningTableStatus.available => 'Free',
    DiningTableStatus.occupied => 'Occupied',
    DiningTableStatus.reserved => 'Reserved',
    DiningTableStatus.unavailable => 'Unavailable',
  };
}
