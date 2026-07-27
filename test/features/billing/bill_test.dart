import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/billing/domain/entities/bill.dart';

void main() {
  test('amount due preserves integer-minor payment arithmetic', () {
    const bill = Bill(
      orderId: 'order-1',
      orderNumber: 42,
      status: BillStatus.billed,
      lines: [],
      totalAmount: 1299,
      paidAmount: 500,
    );

    expect(bill.amountDue, 799);
  });

  test('bank transfer uses its database status value', () {
    expect(PaymentMethod.bankTransfer.databaseValue, 'bank_transfer');
  });
}
