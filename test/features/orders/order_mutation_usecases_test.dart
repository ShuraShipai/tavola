import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/orders/domain/entities/restaurant_order.dart';
import 'package:tavola/features/orders/domain/repositories/restaurant_order_repository.dart';
import 'package:tavola/features/orders/domain/usecases/create_restaurant_order.dart';
import 'package:tavola/features/orders/domain/usecases/transition_restaurant_order.dart';

void main() {
  test('dine-in order requires a table before it reaches the repository', () {
    final repository = _Repository();
    expect(
      () => CreateRestaurantOrder(repository)(
        const CreateOrderInput(
          restaurantId: 'restaurant-a',
          orderType: RestaurantOrderType.dineIn,
          items: [OrderItemInput(menuItemId: 'item-a', quantity: 1)],
        ),
      ),
      throwsArgumentError,
    );
    expect(repository.created, isFalse);
  });

  test('illegal status transitions are rejected locally', () {
    final repository = _Repository();
    expect(
      () => TransitionRestaurantOrder(repository)(
        restaurantId: 'restaurant-a',
        orderId: 'order-a',
        from: RestaurantOrderStatus.open,
        to: RestaurantOrderStatus.paid,
      ),
      throwsArgumentError,
    );
    expect(repository.transitioned, isFalse);
  });

  test('a held draft can be resumed and sent to the kitchen', () {
    expect(
      RestaurantOrderStatus.draft.canTransitionTo(
        RestaurantOrderStatus.sentToKitchen,
      ),
      isTrue,
    );
  });
}

class _Repository implements RestaurantOrderRepository {
  bool created = false;
  bool transitioned = false;

  @override
  Future<RestaurantOrder> createOrder(CreateOrderInput input) async {
    created = true;
    throw UnimplementedError();
  }

  @override
  Future<RestaurantOrder> createHeldOrder(CreateOrderInput input) =>
      throw UnimplementedError();

  @override
  Future<List<RestaurantOrder>> getOrders(String restaurantId) async =>
      const [];

  @override
  Stream<List<RestaurantOrder>> watchOrders(String restaurantId) =>
      const Stream.empty();

  @override
  Future<RestaurantOrder> transitionOrder({
    required String restaurantId,
    required String orderId,
    required RestaurantOrderStatus from,
    required RestaurantOrderStatus to,
  }) async {
    transitioned = true;
    throw UnimplementedError();
  }

  @override
  Future<RestaurantOrder> cancelOrder({
    required String restaurantId,
    required String orderId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<RestaurantOrder> updateOrder(UpdateOrderInput input) =>
      throw UnimplementedError();
}
