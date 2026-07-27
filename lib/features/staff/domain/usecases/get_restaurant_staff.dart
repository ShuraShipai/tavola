import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class GetRestaurantStaff {
  const GetRestaurantStaff(this._repository);
  final StaffRepository _repository;

  Future<List<StaffMember>> call(String restaurantId) =>
      _repository.getStaff(restaurantId);
}
