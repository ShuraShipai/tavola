import '../entities/branch.dart';
import '../repositories/branch_repository.dart';

class GetRestaurantBranches {
  const GetRestaurantBranches(this._repository);
  final BranchRepository _repository;

  Future<List<Branch>> call(String restaurantId) =>
      _repository.getBranches(restaurantId);
}
