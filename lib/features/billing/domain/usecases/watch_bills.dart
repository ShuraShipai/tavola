import '../entities/bill.dart';
import '../repositories/billing_repository.dart';

class WatchBills {
  const WatchBills(this._repository);
  final BillingRepository _repository;

  Stream<List<Bill>> call(String restaurantId) =>
      _repository.watchBills(restaurantId);
}
