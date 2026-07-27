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
    String? restaurantType,
    String? phone,
  }) => _run(
    () => SignUp(_repository)(
      email: email,
      password: password,
      fullName: fullName,
      restaurantType: restaurantType,
      phone: phone,
    ),
  );

  Future<void> createRestaurant({
    required String name,
    String? restaurantType,
    String? phone,
  }) => _run(() async {
    await CreateRestaurant(_repository)(
      name: name,
      timezone: 'Asia/Kolkata',
      restaurantType: restaurantType,
      phone: phone,
    );
    ref.invalidate(currentMembershipProvider);
  });

  Future<void> redeemRestaurantInvitation({
    required String restaurantCode,
    required String inviteCode,
  }) => _run(() async {
    await RedeemRestaurantInvitation(_repository)(
      restaurantCode: restaurantCode,
      inviteCode: inviteCode,
    );
    ref.invalidate(currentMembershipProvider);
  });

  Future<bool> verifyStaffPin({
    required String restaurantId,
    required String pin,
  }) async {
    state = const AsyncLoading();
    try {
      final valid = await _repository.verifyStaffPin(
        restaurantId: restaurantId,
        pin: pin,
      );
      state = const AsyncData(null);
      return valid;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _run(() => _repository.sendPasswordReset(email));

  Future<void> signOut() => _run(() async {
    await _repository.signOut();
    ref.invalidate(currentMembershipProvider);
  });

  Future<void> updateProfile({required String fullName, String? phone}) =>
      _run(() => UpdateProfile(_repository)(fullName: fullName, phone: phone));

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }

  @override
  Future<void> build() async {}
}
