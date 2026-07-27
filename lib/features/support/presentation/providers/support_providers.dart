import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/supabase_support_repository.dart';
import '../../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseSupportRepository(client);
});
