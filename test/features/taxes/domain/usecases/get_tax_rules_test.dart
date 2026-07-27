import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/taxes/domain/entities/tax_rule.dart';
import 'package:tavola/features/taxes/domain/repositories/tax_rule_repository.dart';
import 'package:tavola/features/taxes/domain/usecases/get_tax_rules.dart';

void main() {
  test('gets tax rules for the current restaurant id', () async {
    final repository = _TaxRepository();
    final rules = await GetTaxRules(repository)('restaurant-1');
    expect(repository.restaurantId, 'restaurant-1');
    expect(rules.single.rateBasisPoints, 500);
  });
}

class _TaxRepository implements TaxRuleRepository {
  String? restaurantId;
  @override
  Future<List<TaxRule>> getRules(String id) async {
    restaurantId = id;
    return const [
      TaxRule(id: 'tax-1', name: 'GST', rateBasisPoints: 500, isActive: true),
    ];
  }

  @override
  Future<void> deleteRule(String id) async {}
  @override
  Future<void> saveRule({
    required String restaurantId,
    String? id,
    required String name,
    required int rateBasisPoints,
    bool isActive = true,
  }) async {}
}
