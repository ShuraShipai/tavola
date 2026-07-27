import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class CreateRestaurantOrder {
  const CreateRestaurantOrder(this._repository);
  final RestaurantOrderRepository _repository;

  Future<RestaurantOrder> call(CreateOrderInput input) {
    if (input.items.isEmpty) {
      throw ArgumentError.value(
        input.items,
        'items',
        'An order needs one item.',
      );
    }
    if (input.items.any((item) => item.quantity <= 0)) {
      throw ArgumentError.value(
        input.items,
        'items',
        'Item quantity must be positive.',
      );
    }
    if (input.orderType == RestaurantOrderType.dineIn &&
        input.tableId == null) {
      throw ArgumentError('Dine-in orders require a table.');
    }
    return _repository.createOrder(input);
  }
}
