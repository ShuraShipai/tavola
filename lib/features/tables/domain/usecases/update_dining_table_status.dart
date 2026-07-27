import '../entities/dining_table.dart';
import '../repositories/dining_table_repository.dart';

class UpdateDiningTableStatus {
  const UpdateDiningTableStatus(this._repository);
  final DiningTableRepository _repository;

  Future<void> call({
    required String restaurantId,
    required String tableId,
    required DiningTableStatus status,
  }) => _repository.updateStatus(
    restaurantId: restaurantId,
    tableId: tableId,
    status: status,
  );
}
