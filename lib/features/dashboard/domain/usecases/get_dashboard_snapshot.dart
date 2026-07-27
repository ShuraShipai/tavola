import '../entities/dashboard_snapshot.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSnapshot {
  const GetDashboardSnapshot(this._repository);
  final DashboardRepository _repository;
  Future<DashboardSnapshot> call(String restaurantId, DateTime now) =>
      _repository.getSnapshot(restaurantId, now);
}
