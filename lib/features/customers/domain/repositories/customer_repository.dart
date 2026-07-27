import '../entities/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> getCustomers(String restaurantId);
  Future<List<Customer>> searchCustomers(String restaurantId, String query);
  Future<void> saveCustomer({
    required String restaurantId,
    String? id,
    required String fullName,
    String? phone,
    String? email,
    String? notes,
  });
  Future<void> associateWithOrder({
    required String orderId,
    required String customerId,
  });
}
