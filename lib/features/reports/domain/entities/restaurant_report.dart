class RestaurantReport {
  const RestaurantReport({
    required this.periodStart,
    required this.periodEnd,
    required this.netSalesAmount,
    required this.orderCount,
    required this.refundAmount,
    required this.dailySales,
    required this.paymentMix,
    required this.recentPayments,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int netSalesAmount;
  final int orderCount;
  final int refundAmount;
  final List<DailySales> dailySales;
  final List<PaymentMethodTotal> paymentMix;
  final List<ReportPayment> recentPayments;

  int get averageOrderAmount =>
      orderCount == 0 ? 0 : netSalesAmount ~/ orderCount;
}

class DailySales {
  const DailySales({required this.date, required this.amount});
  final DateTime date;
  final int amount;
}

class PaymentMethodTotal {
  const PaymentMethodTotal({required this.method, required this.amount});
  final String method;
  final int amount;
}

class ReportPayment {
  const ReportPayment({
    required this.orderId,
    required this.method,
    required this.amount,
    required this.paidAt,
  });
  final String orderId;
  final String method;
  final int amount;
  final DateTime paidAt;
}
