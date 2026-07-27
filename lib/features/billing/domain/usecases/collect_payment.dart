import '../entities/bill.dart';
import '../repositories/billing_repository.dart';

class CollectPayment {
  const CollectPayment(this._repository);
  final BillingRepository _repository;
  Future<void> call({
    required String orderId,
    required PaymentMethod method,
    required int amount,
    String? externalReference,
  }) => _repository.collectPayment(
    orderId: orderId,
    method: method,
    amount: amount,
    externalReference: externalReference,
  );
}
