import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class CancelRestaurantOrder {
  const CancelRestaurantOrder(this._repository);
  final RestaurantOrderRepository _repository;

  Future<RestaurantOrder> call({
    required String restaurantId,
    required String orderId,
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'is required');
    }
    return _repository.cancelOrder(
      restaurantId: restaurantId,
      orderId: orderId,
      reason: reason.trim(),
    );
  }
}
