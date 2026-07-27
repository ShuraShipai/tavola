import '../entities/discount_entities.dart';

abstract interface class DiscountRepository {
  Future<DiscountCatalog> getCatalog(String restaurantId);
  Future<void> saveDiscount({
    required String restaurantId,
    String? id,
    required String name,
    required String type,
    required int value,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive,
  });
  Future<void> saveCoupon({
    required String restaurantId,
    String? id,
    required String discountId,
    required String code,
    DateTime? startsAt,
    DateTime? endsAt,
    int? redemptionLimit,
    int minimumOrderAmount,
    bool isActive,
  });
  Future<void> deleteDiscount(String id);
  Future<void> deleteCoupon(String id);
}
