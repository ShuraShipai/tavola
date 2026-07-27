import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_tax_rule_repository.dart';
import '../../domain/entities/tax_rule.dart';
import '../../domain/repositories/tax_rule_repository.dart';
import '../../domain/usecases/get_tax_rules.dart';

final taxRuleRepositoryProvider = Provider<TaxRuleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseTaxRuleRepository(client);
});
final getTaxRulesProvider = Provider(
  (ref) => GetTaxRules(ref.watch(taxRuleRepositoryProvider)),
);
final taxRulesProvider = FutureProvider<List<TaxRule>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) {
    throw StateError('Choose a restaurant before loading tax rules.');
  }
  return ref.watch(getTaxRulesProvider)(membership.restaurantId);
});
