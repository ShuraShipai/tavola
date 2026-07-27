import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItems {
  const GetInventoryItems(this._repository);
  final InventoryRepository _repository;
  Future<List<InventoryItem>> call(String restaurantId) =>
      _repository.getInventoryItems(restaurantId);
}
