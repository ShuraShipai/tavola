import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class WatchRestaurantOrders {
  const WatchRestaurantOrders(this._repository);
  final RestaurantOrderRepository _repository;

  Stream<List<RestaurantOrder>> call(String restaurantId) =>
      _repository.watchOrders(restaurantId);
}
