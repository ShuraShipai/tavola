import '../entities/restaurant_report.dart';
import '../repositories/report_repository.dart';

class GetRestaurantReport {
  const GetRestaurantReport(this._repository);
  final ReportRepository _repository;

  Future<RestaurantReport> call({
    required String restaurantId,
    required DateTime periodEnd,
    int periodDays = 7,
  }) => _repository.getReport(
    restaurantId: restaurantId,
    periodEnd: periodEnd,
    periodDays: periodDays,
  );
}
