import '../entities/branch.dart';

abstract interface class BranchRepository {
  Future<List<Branch>> getBranches(String restaurantId);
  Future<void> saveBranch({
    required String restaurantId,
    String? id,
    required String name,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    String? timezone,
    bool isActive,
  });
  Future<void> deleteBranch(String id);
}
