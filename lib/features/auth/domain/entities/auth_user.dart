class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.pendingRestaurantType,
    this.pendingPhone,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? pendingRestaurantType;
  final String? pendingPhone;
}
