enum TavolaRole { owner, manager, cashier, waiter, kitchen }

extension TavolaRoleX on TavolaRole {
  String get label => switch (this) {
    TavolaRole.owner => 'Owner',
    TavolaRole.manager => 'Manager',
    TavolaRole.cashier => 'Cashier',
    TavolaRole.waiter => 'Waiter',
    TavolaRole.kitchen => 'Kitchen',
  };
}

class RestaurantMembership {
  const RestaurantMembership({
    required this.restaurantId,
    required this.restaurantName,
    required this.role,
    required this.currencyCode,
  });

  final String restaurantId;
  final String restaurantName;
  final TavolaRole role;
  final String currencyCode;
}
