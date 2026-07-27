import '../entities/bill.dart';
import '../repositories/billing_repository.dart';

class GetBills {
  const GetBills(this._repository);
  final BillingRepository _repository;
  Future<List<Bill>> call(String restaurantId) =>
      _repository.getBills(restaurantId);
}
