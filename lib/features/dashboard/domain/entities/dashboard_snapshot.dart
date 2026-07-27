class DashboardSnapshot {
  const DashboardSnapshot({
    required this.todaySalesAmount,
    required this.todayOrderCount,
    required this.occupiedTables,
    required this.totalTables,
    required this.reservedTables,
    required this.weeklySales,
    required this.topItems,
    required this.recentOrders,
  });
  final int todaySalesAmount;
  final int todayOrderCount;
  final int occupiedTables;
  final int totalTables;
  final int reservedTables;
  final List<DailySales> weeklySales;
  final List<TopSellingItem> topItems;
  final List<DashboardOrder> recentOrders;
  int get availableTables => totalTables - occupiedTables - reservedTables;
  int get averageOrderAmount =>
      todayOrderCount == 0 ? 0 : (todaySalesAmount / todayOrderCount).round();
}

class DailySales {
  const DailySales({required this.label, required this.amount});
  final String label;
  final int amount;
}

class TopSellingItem {
  const TopSellingItem({required this.name, required this.quantity});
  final String name;
  final num quantity;
}

class DashboardOrder {
  const DashboardOrder({
    required this.id,
    required this.number,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.tableLabel,
    this.itemSummary = '',
  });
  final String id;
  final int number;
  final String orderType, status, itemSummary;
  final int totalAmount;
  final DateTime createdAt;
  final String? tableLabel;
}
