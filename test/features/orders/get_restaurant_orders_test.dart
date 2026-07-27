import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/orders/domain/entities/restaurant_order.dart';
import 'package:tavola/features/orders/domain/repositories/restaurant_order_repository.dart';
import 'package:tavola/features/orders/domain/usecases/get_restaurant_orders.dart';

void main() {
  test('gets orders for the requested restaurant only', () async {
    final repository = _FakeRestaurantOrderRepository();
    final result = await GetRestaurantOrders(repository)('restaurant-a');

    expect(repository.requestedRestaurantId, 'restaurant-a');
    expect(result.single.orderNumber, 1042);
    expect(result.single.totalAmount, 94600);
  });
}

class _FakeRestaurantOrderRepository implements RestaurantOrderRepository {
  String? requestedRestaurantId;

  @override
  Future<List<RestaurantOrder>> getOrders(String restaurantId) async {
    requestedRestaurantId = restaurantId;
    return [
      RestaurantOrder(
        id: 'order-1',
        restaurantId: restaurantId,
        branchId: 'branch-1',
        orderNumber: 1042,
        status: RestaurantOrderStatus.preparing,
        orderType: RestaurantOrderType.dineIn,
        totalAmount: 94600,
        createdAt: DateTime.utc(2026, 7, 25),
        openedAt: null,
      ),
    ];
  }

  @override
  Stream<List<RestaurantOrder>> watchOrders(String restaurantId) =>
      Stream.value(const []);

  @override
  Future<RestaurantOrder> createOrder(CreateOrderInput input) =>
      throw UnimplementedError();

  @override
  Future<RestaurantOrder> transitionOrder({
    required String restaurantId,
    required String orderId,
    required RestaurantOrderStatus from,
    required RestaurantOrderStatus to,
  }) => throw UnimplementedError();

  @override
  Future<RestaurantOrder> updateOrder(UpdateOrderInput input) =>
      throw UnimplementedError();
}
