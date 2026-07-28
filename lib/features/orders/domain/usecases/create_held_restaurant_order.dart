import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

/// Persists an editable order draft without sending it to the kitchen.
class CreateHeldRestaurantOrder {
  const CreateHeldRestaurantOrder(this._repository);

  final RestaurantOrderRepository _repository;

  Future<RestaurantOrder> call(CreateOrderInput input) {
    if (input.items.isEmpty || input.items.any((item) => item.quantity <= 0)) {
      throw ArgumentError(
        'A held order needs item quantities greater than zero.',
      );
    }
    if (input.orderType == RestaurantOrderType.dineIn &&
        input.tableId == null) {
      throw ArgumentError('Dine-in orders require a table.');
    }
    return _repository.createHeldOrder(input);
  }
}
