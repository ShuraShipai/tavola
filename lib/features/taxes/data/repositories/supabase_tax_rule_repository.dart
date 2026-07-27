import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/tax_rule.dart';
import '../../domain/repositories/tax_rule_repository.dart';

class SupabaseTaxRuleRepository implements TaxRuleRepository {
  SupabaseTaxRuleRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<List<TaxRule>> getRules(String restaurantId) async {
    final rows =
        await _client
                .from('tax_rules')
                .select()
                .eq('restaurant_id', restaurantId)
                .order('name')
            as List<dynamic>;
    return rows
        .cast<Map<String, dynamic>>()
        .map(
          (row) => TaxRule(
            id: row['id'].toString(),
            name: row['name'] as String? ?? 'Unnamed tax',
            rateBasisPoints: (row['rate_basis_points'] as num?)?.toInt() ?? 0,
            isActive: row['is_active'] as bool? ?? true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveRule({
    required String restaurantId,
    String? id,
    required String name,
    required int rateBasisPoints,
    bool isActive = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'rate_basis_points': rateBasisPoints,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('tax_rules').insert(row);
    } else {
      await _client.from('tax_rules').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteRule(String id) =>
      _client.from('tax_rules').delete().eq('id', id);
}
