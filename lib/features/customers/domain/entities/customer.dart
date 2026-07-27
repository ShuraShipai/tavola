class Customer {
  const Customer({
    required this.id,
    required this.restaurantId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.notes,
    required this.visitCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String restaurantId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? notes;
  final int visitCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
