import '../entities/dining_table.dart';

abstract interface class DiningTableRepository {
  Future<List<DiningTable>> getTables(String restaurantId);
  Stream<List<DiningTable>> watchTables(String restaurantId);
  Future<void> seatTable({
    required String tableId,
    required int expectedVersion,
  });
  Future<void> assignOrder({
    required String orderId,
    required String tableId,
    required int expectedTableVersion,
  });
  Future<String> mergeTables({
    required String primaryTableId,
    required List<String> secondaryTableIds,
  });
  Future<void> splitMerge(String mergeId);

  Future<void> updateStatus({
    required String restaurantId,
    required String tableId,
    required DiningTableStatus status,
  });
}
