import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/customers/domain/entities/customer.dart';
import 'package:tavola/features/customers/domain/repositories/customer_repository.dart';
import 'package:tavola/features/customers/domain/usecases/get_restaurant_customers.dart';

void main() {
  test('gets customers for the requested restaurant only', () async {
    final repository = _FakeCustomerRepository();
    final result = await GetRestaurantCustomers(repository)('restaurant-a');

    expect(repository.requestedRestaurantId, 'restaurant-a');
    expect(result.single.fullName, 'Arjun Mehta');
  });
}

class _FakeCustomerRepository implements CustomerRepository {
  String? requestedRestaurantId;

  @override
  Future<List<Customer>> getCustomers(String restaurantId) async {
    requestedRestaurantId = restaurantId;
    return [
      Customer(
        id: 'customer-1',
        restaurantId: 'restaurant-a',
        fullName: 'Arjun Mehta',
        phone: null,
        email: null,
        notes: null,
        visitCount: 2,
        createdAt: DateTime.utc(2026, 7, 25),
        updatedAt: DateTime.utc(2026, 7, 25),
      ),
    ];
  }

  @override
  Future<void> associateWithOrder({
    required String orderId,
    required String customerId,
  }) async {}
  @override
  Future<void> saveCustomer({
    required String restaurantId,
    String? id,
    required String fullName,
    String? phone,
    String? email,
    String? notes,
  }) async {}
  @override
  Future<List<Customer>> searchCustomers(String restaurantId, String query) =>
      getCustomers(restaurantId);
}
