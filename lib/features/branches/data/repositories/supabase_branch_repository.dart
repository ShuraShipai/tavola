import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';

class SupabaseBranchRepository implements BranchRepository {
  SupabaseBranchRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Branch>> getBranches(String restaurantId) async {
    final rows = await _client
        .from('branches')
        .select(
          'id, restaurant_id, name, address, phone, is_active, opens_at, closes_at, timezone',
        )
        .eq('restaurant_id', restaurantId)
        .order('name');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => Branch(
            id: row['id'] as String,
            restaurantId: row['restaurant_id'] as String,
            name: row['name'] as String,
            address: row['address'] as String?,
            phone: row['phone'] as String?,
            isActive: row['is_active'] as bool,
            opensAt: row['opens_at'] as String?,
            closesAt: row['closes_at'] as String?,
            timezone: row['timezone'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveBranch({
    required String restaurantId,
    String? id,
    required String name,
    String? address,
    String? phone,
    String? opensAt,
    String? closesAt,
    String? timezone,
    bool isActive = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'address': address?.trim(),
      'phone': phone?.trim(),
      'is_active': isActive,
      'opens_at': opensAt,
      'closes_at': closesAt,
      'timezone': timezone,
    };
    if (id == null) {
      await _client.from('branches').insert(row);
    } else {
      await _client.from('branches').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteBranch(String id) =>
      _client.from('branches').delete().eq('id', id);
}
