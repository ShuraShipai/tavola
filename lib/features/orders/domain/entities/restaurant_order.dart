class RestaurantOrder {
  const RestaurantOrder({
    required this.id,
    required this.restaurantId,
    required this.orderNumber,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    required this.createdAt,
    required this.openedAt,
    this.tableId,
    this.customerId,
    this.notes,
    this.items = const [],
  });

  final String id;
  final String restaurantId;
  final int orderNumber;
  final RestaurantOrderStatus status;
  final RestaurantOrderType orderType;
  final int totalAmount;
  final DateTime createdAt;
  final DateTime? openedAt;
  final String? tableId;
  final String? customerId;
  final String? notes;
  final List<OrderLine> items;
}

/// A menu snapshot held by an order. Amounts are always integer minor units.
class OrderLine {
  const OrderLine({
    required this.menuItemId,
    required this.name,
    required this.unitPriceAmount,
    required this.quantity,
    required this.taxAmount,
    required this.lineTotalAmount,
    this.notes,
  });

  final String? menuItemId;
  final String name;
  final int unitPriceAmount;
  final num quantity;
  final int taxAmount;
  final int lineTotalAmount;
  final String? notes;
}

enum RestaurantOrderStatus {
  draft,
  open,
  sentToKitchen,
  preparing,
  ready,
  served,
  billed,
  paid,
  cancelled,
}

extension RestaurantOrderStatusX on RestaurantOrderStatus {
  String get label => switch (this) {
    RestaurantOrderStatus.sentToKitchen => 'Sent to kitchen',
    _ => name[0].toUpperCase() + name.substring(1),
  };

  bool canTransitionTo(RestaurantOrderStatus next) => switch ((this, next)) {
    (RestaurantOrderStatus.draft, RestaurantOrderStatus.open) ||
    (RestaurantOrderStatus.draft, RestaurantOrderStatus.sentToKitchen) ||
    (RestaurantOrderStatus.draft, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.open, RestaurantOrderStatus.sentToKitchen) ||
    (RestaurantOrderStatus.open, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.sentToKitchen, RestaurantOrderStatus.preparing) ||
    (RestaurantOrderStatus.sentToKitchen, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.preparing, RestaurantOrderStatus.ready) ||
    (RestaurantOrderStatus.preparing, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.ready, RestaurantOrderStatus.served) ||
    (RestaurantOrderStatus.ready, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.served, RestaurantOrderStatus.billed) ||
    (RestaurantOrderStatus.served, RestaurantOrderStatus.cancelled) ||
    (RestaurantOrderStatus.billed, RestaurantOrderStatus.paid) => true,
    _ => false,
  };
}

enum RestaurantOrderType { dineIn, takeaway, delivery }

extension RestaurantOrderTypeX on RestaurantOrderType {
  String get label => switch (this) {
    RestaurantOrderType.dineIn => 'Dine-in',
    RestaurantOrderType.takeaway => 'Takeaway',
    RestaurantOrderType.delivery => 'Delivery',
  };
}
