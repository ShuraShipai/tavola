import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/restaurant_membership.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase is not configured.');
  return SupabaseAuthRepository(client);
});

final authUserProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.watchAuthUser();
});

final currentMembershipProvider = FutureProvider<RestaurantMembership?>((
  ref,
) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getMembership(user.id);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

extension AsyncValueDataX<T> on AsyncValue<T> {
  T? get dataOrNull =>
      when(data: (value) => value, loading: () => null, error: (_, _) => null);
}

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) =>
      _run(() => SignIn(_repository)(email: email, password: password));

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) => _run(
    () => SignUp(_repository)(
      email: email,
      password: password,
      fullName: fullName,
    ),
  );

  Future<void> createRestaurant({required String name}) => _run(() async {
    await CreateRestaurant(_repository)(name: name, timezone: 'Asia/Kolkata');
    ref.invalidate(currentMembershipProvider);
  });

  Future<void> sendPasswordReset(String email) =>
      _run(() => _repository.sendPasswordReset(email));

  Future<void> signOut() => _run(() async {
    await _repository.signOut();
    ref.invalidate(currentMembershipProvider);
  });

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }

  @override
  Future<void> build() async {}
}
