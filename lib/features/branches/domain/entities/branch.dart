class Branch {
  const Branch({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
    this.opensAt,
    this.closesAt,
    this.timezone,
  });

  final String id;
  final String restaurantId;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final String? opensAt;
  final String? closesAt;
  final String? timezone;
}
