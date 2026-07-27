import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetRestaurantCustomers {
  const GetRestaurantCustomers(this._repository);
  final CustomerRepository _repository;

  Future<List<Customer>> call(String restaurantId) =>
      _repository.getCustomers(restaurantId);
}
