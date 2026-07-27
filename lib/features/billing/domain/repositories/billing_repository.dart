import '../entities/bill.dart';

abstract interface class BillingRepository {
  Future<List<Bill>> getBills(String restaurantId);
  Stream<List<Bill>> watchBills(String restaurantId);
  Future<void> collectPayment({
    required String orderId,
    required PaymentMethod method,
    required int amount,
    String? externalReference,
  });
}
