import '../entities/restaurant_order.dart';

abstract interface class RestaurantOrderRepository {
  Future<List<RestaurantOrder>> getOrders(String restaurantId);
  Stream<List<RestaurantOrder>> watchOrders(String restaurantId);

  Future<RestaurantOrder> createOrder(CreateOrderInput input);
  Future<RestaurantOrder> updateOrder(UpdateOrderInput input);
  Future<RestaurantOrder> transitionOrder({
    required String restaurantId,
    required String orderId,
    required RestaurantOrderStatus from,
    required RestaurantOrderStatus to,
  });
}

class OrderItemInput {
  const OrderItemInput({
    required this.menuItemId,
    required this.quantity,
    this.notes,
  });
  final String menuItemId;
  final num quantity;
  final String? notes;
}

class CreateOrderInput {
  const CreateOrderInput({
    required this.restaurantId,
    required this.items,
    required this.orderType,
    this.tableId,
    this.customerId,
    this.notes,
  });
  final String restaurantId;
  final List<OrderItemInput> items;
  final RestaurantOrderType orderType;
  final String? tableId;
  final String? customerId;
  final String? notes;
}

class UpdateOrderInput extends CreateOrderInput {
  const UpdateOrderInput({
    required this.orderId,
    required super.restaurantId,
    required super.items,
    required super.orderType,
    super.tableId,
    super.customerId,
    super.notes,
  });
  final String orderId;
}
