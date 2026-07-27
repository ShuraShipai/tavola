import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class TransitionRestaurantOrder {
  const TransitionRestaurantOrder(this._repository);
  final RestaurantOrderRepository _repository;

  Future<RestaurantOrder> call({
    required String restaurantId,
    required String orderId,
    required RestaurantOrderStatus from,
    required RestaurantOrderStatus to,
  }) {
    if (!from.canTransitionTo(to)) {
      throw ArgumentError('Cannot transition ${from.label} to ${to.label}.');
    }
    return _repository.transitionOrder(
      restaurantId: restaurantId,
      orderId: orderId,
      from: from,
      to: to,
    );
  }
}
