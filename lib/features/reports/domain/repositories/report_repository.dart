import '../entities/restaurant_report.dart';

abstract interface class ReportRepository {
  Future<RestaurantReport> getReport({
    required String restaurantId,
    required DateTime periodEnd,
    int periodDays = 7,
  });
}
