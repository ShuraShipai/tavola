import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/discount_entities.dart';
import '../../domain/repositories/discount_repository.dart';

class SupabaseDiscountRepository implements DiscountRepository {
  SupabaseDiscountRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<DiscountCatalog> getCatalog(String restaurantId) async {
    final responses = await Future.wait([
      _client
          .from('discounts')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('name'),
      _client
          .from('coupons')
          .select(
            'id, code, discount_id, is_active, redemption_count, redemption_limit, starts_at, ends_at, minimum_order_amount, discounts(name)',
          )
          .eq('restaurant_id', restaurantId)
          .order('code'),
    ]);
    final discounts = responses.first as List<dynamic>;
    final coupons = responses.last as List<dynamic>;
    return DiscountCatalog(
      discounts: discounts
          .cast<Map<String, dynamic>>()
          .map(
            (row) => Discount(
              id: row['id'].toString(),
              name: row['name'] as String? ?? 'Unnamed discount',
              type: row['discount_type'] as String? ?? 'percentage',
              value: (row['value'] as num?)?.toInt() ?? 0,
              isActive: row['is_active'] as bool? ?? true,
              usageCount: (row['usage_count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(growable: false),
      coupons: coupons
          .cast<Map<String, dynamic>>()
          .map((row) {
            final discount = row['discounts'] as Map<String, dynamic>?;
            return Coupon(
              id: row['id'].toString(),
              code: row['code'] as String,
              discountLabel: discount?['name'] as String? ?? 'Discount',
              isActive: row['is_active'] as bool,
              redemptionCount: (row['redemption_count'] as num).toInt(),
              redemptionLimit: (row['redemption_limit'] as num?)?.toInt(),
              startsAt: row['starts_at'] == null
                  ? null
                  : DateTime.parse(row['starts_at'] as String),
              endsAt: row['ends_at'] == null
                  ? null
                  : DateTime.parse(row['ends_at'] as String),
              minimumOrderAmount:
                  (row['minimum_order_amount'] as num?)?.toInt() ?? 0,
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Future<void> saveDiscount({
    required String restaurantId,
    String? id,
    required String name,
    required String type,
    required int value,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'name': name.trim(),
      'discount_type': type,
      'value': value,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('discounts').insert(row);
    } else {
      await _client.from('discounts').update(row).eq('id', id);
    }
  }

  @override
  Future<void> saveCoupon({
    required String restaurantId,
    String? id,
    required String discountId,
    required String code,
    DateTime? startsAt,
    DateTime? endsAt,
    int? redemptionLimit,
    int minimumOrderAmount = 0,
    bool isActive = true,
  }) async {
    final row = {
      'restaurant_id': restaurantId,
      'discount_id': discountId,
      'code': code.trim().toUpperCase(),
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'redemption_limit': redemptionLimit,
      'minimum_order_amount': minimumOrderAmount,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('coupons').insert(row);
    } else {
      await _client.from('coupons').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteDiscount(String id) =>
      _client.from('discounts').delete().eq('id', id);
  @override
  Future<void> deleteCoupon(String id) =>
      _client.from('coupons').delete().eq('id', id);
}
