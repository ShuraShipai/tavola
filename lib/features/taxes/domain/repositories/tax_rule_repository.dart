import '../entities/tax_rule.dart';

abstract interface class TaxRuleRepository {
  Future<List<TaxRule>> getRules(String restaurantId);
  Future<void> saveRule({
    required String restaurantId,
    String? id,
    required String name,
    required int rateBasisPoints,
    bool isActive,
  });
  Future<void> deleteRule(String id);
}
