import '../entities/restaurant_order.dart';
import '../repositories/restaurant_order_repository.dart';

class GetRestaurantOrders {
  const GetRestaurantOrders(this._repository);
  final RestaurantOrderRepository _repository;

  Future<List<RestaurantOrder>> call(String restaurantId) =>
      _repository.getOrders(restaurantId);
}
