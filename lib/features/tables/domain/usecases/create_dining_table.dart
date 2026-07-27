import '../repositories/dining_table_repository.dart';

class CreateDiningTable {
  const CreateDiningTable(this._repository);

  final DiningTableRepository _repository;

  Future<void> call({
    required String restaurantId,
    String? tableId,
    String? branchId,
    required String label,
    required int capacity,
    required int sortOrder,
    String? currentStatusDetail,
  }) => _repository.saveTable(
    restaurantId: restaurantId,
    tableId: tableId,
    branchId: branchId,
    label: label,
    capacity: capacity,
    sortOrder: sortOrder,
    currentStatusDetail: currentStatusDetail,
  );
}
