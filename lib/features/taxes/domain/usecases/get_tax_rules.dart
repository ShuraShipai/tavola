import '../entities/tax_rule.dart';
import '../repositories/tax_rule_repository.dart';

class GetTaxRules {
  const GetTaxRules(this._repository);
  final TaxRuleRepository _repository;
  Future<List<TaxRule>> call(String restaurantId) =>
      _repository.getRules(restaurantId);
}
