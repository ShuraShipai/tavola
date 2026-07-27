import '../entities/staff_member.dart';

abstract interface class StaffRepository {
  Future<List<StaffMember>> getStaff(String restaurantId);
  Future<void> setStaffPin({required String membershipId, required String pin});
  Future<void> updateMembership({
    required String membershipId,
    StaffRole? role,
    bool? isActive,
  });
}
