import '../entities/dining_table.dart';
import '../repositories/dining_table_repository.dart';

class WatchRestaurantTables {
  const WatchRestaurantTables(this._repository);
  final DiningTableRepository _repository;

  Stream<List<DiningTable>> call(String restaurantId) =>
      _repository.watchTables(restaurantId);
}
