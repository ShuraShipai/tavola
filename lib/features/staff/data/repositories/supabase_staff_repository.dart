import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/staff_repository.dart';

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<StaffMember>> getStaff(String restaurantId) async {
    final membershipRows = await _client
        .from('restaurant_memberships')
        .select('id, restaurant_id, user_id, role, is_active')
        .eq('restaurant_id', restaurantId)
        .order('created_at');
    final memberships = (membershipRows as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (memberships.isEmpty) return const [];

    final userIds = memberships.map((row) => row['user_id'] as String).toList();
    final profileRows = await _client
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', userIds);
    final profiles = <String, Map<String, dynamic>>{
      for (final row
          in (profileRows as List<dynamic>).cast<Map<String, dynamic>>())
        row['id'] as String: row,
    };

    return memberships
        .map((row) {
          final profile = profiles[row['user_id'] as String];
          return StaffMember(
            id: row['id'] as String,
            restaurantId: row['restaurant_id'] as String,
            userId: row['user_id'] as String,
            role: StaffRole.values.byName(row['role'] as String),
            isActive: row['is_active'] as bool,
            fullName: profile?['full_name'] as String?,
            email: profile?['email'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> setStaffPin({
    required String membershipId,
    required String pin,
  }) async {
    await _client.rpc(
      'set_staff_pin',
      params: {'p_membership_id': membershipId, 'p_pin': pin},
    );
  }

  @override
  Future<void> updateMembership({
    required String membershipId,
    StaffRole? role,
    bool? isActive,
  }) => _client.rpc(
    'update_staff_membership',
    params: {
      'p_membership_id': membershipId,
      'p_role': role?.name,
      'p_is_active': isActive,
    },
  );
}
