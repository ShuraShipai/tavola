enum StaffRole { owner, manager, cashier, waiter, kitchen }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
    StaffRole.owner => 'Owner',
    StaffRole.manager => 'Manager',
    StaffRole.cashier => 'Cashier',
    StaffRole.waiter => 'Waiter',
    StaffRole.kitchen => 'Kitchen',
  };
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.role,
    required this.isActive,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String restaurantId;
  final String userId;
  final StaffRole role;
  final bool isActive;
  final String? fullName;
  final String? email;
}
