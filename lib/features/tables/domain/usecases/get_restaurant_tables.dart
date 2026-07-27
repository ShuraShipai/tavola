import '../entities/dining_table.dart';
import '../repositories/dining_table_repository.dart';

class GetRestaurantTables {
  const GetRestaurantTables(this._repository);
  final DiningTableRepository _repository;

  Future<List<DiningTable>> call(String restaurantId) =>
      _repository.getTables(restaurantId);
}
