import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class UpdateRestaurantOrder {
  const UpdateRestaurantOrder(this._repository);
  final RestaurantOrderRepository _repository;

  Future<RestaurantOrder> call(UpdateOrderInput input) {
    if (input.items.isEmpty || input.items.any((item) => item.quantity <= 0)) {
      throw ArgumentError('An order needs item quantities greater than zero.');
    }
    if (input.orderType == RestaurantOrderType.dineIn &&
        input.tableId == null) {
      throw ArgumentError('Dine-in orders require a table.');
    }
    return _repository.updateOrder(input);
  }
}
