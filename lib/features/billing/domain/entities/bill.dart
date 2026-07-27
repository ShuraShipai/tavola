class Bill {
  const Bill({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.lines,
    required this.totalAmount,
    required this.paidAmount,
  });
  final String orderId;
  final int orderNumber;
  final BillStatus status;
  final List<BillLine> lines;
  final int totalAmount;
  final int paidAmount;
  int get amountDue => totalAmount - paidAmount;
}

class BillLine {
  const BillLine({
    required this.name,
    required this.quantity,
    required this.lineTotalAmount,
    this.notes,
  });
  final String name;
  final num quantity;
  final int lineTotalAmount;
  final String? notes;
}

enum BillStatus { served, billed, paid }

enum PaymentMethod { cash, card, upi, wallet, bankTransfer, other }

extension PaymentMethodX on PaymentMethod {
  String get databaseValue => switch (this) {
    PaymentMethod.bankTransfer => 'bank_transfer',
    _ => name,
  };
  String get label => switch (this) {
    PaymentMethod.upi => 'UPI',
    PaymentMethod.bankTransfer => 'Bank transfer',
    _ => name[0].toUpperCase() + name.substring(1),
  };
}
