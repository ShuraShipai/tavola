class Discount {
  const Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.isActive,
    this.usageCount = 0,
  });
  final String id;
  final String name;
  final String type;
  final int value;
  final bool isActive;
  final int usageCount;
}

class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.discountLabel,
    required this.isActive,
    this.redemptionCount = 0,
    this.redemptionLimit,
    this.startsAt,
    this.endsAt,
    this.minimumOrderAmount = 0,
  });
  final String id;
  final String code;
  final String discountLabel;
  final bool isActive;
  final int redemptionCount;
  final int? redemptionLimit;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int minimumOrderAmount;
}

class DiscountCatalog {
  const DiscountCatalog({required this.discounts, required this.coupons});
  final List<Discount> discounts;
  final List<Coupon> coupons;
}
