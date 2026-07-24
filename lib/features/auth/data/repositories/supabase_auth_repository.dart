import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/entities/auth_user.dart';
import '../../domain/entities/restaurant_membership.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> watchAuthUser() => _client.auth.onAuthStateChange.map(
    (state) => _mapUser(state.session?.user),
  );

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: _webRedirectUrl,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) => _client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: _webRedirectUrl);

  @override
  Future<RestaurantMembership?> getMembership(String userId) async {
    final rows = await _client
        .from('restaurant_memberships')
        .select('role, restaurant:restaurants(id, name, currency_code)')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final restaurant = row['restaurant'] as Map<String, dynamic>?;
    if (restaurant == null) {
      return null;
    }
    return RestaurantMembership(
      restaurantId: restaurant['id'] as String,
      restaurantName: restaurant['name'] as String,
      currencyCode: restaurant['currency_code'] as String? ?? 'INR',
      role: TavolaRole.values.byName(row['role'] as String),
    );
  }

  @override
  Future<void> createRestaurant({
    required String name,
    required String timezone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in before creating a restaurant.');
    }
    await _client.from('restaurants').insert({
      'name': name.trim(),
      'timezone': timezone,
      'owner_id': user.id,
    });
  }

  AuthUser? _mapUser(User? user) {
    if (user == null || user.email == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email!,
      fullName:
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
    );
  }

  String? get _webRedirectUrl {
    final uri = Uri.base;
    return uri.scheme == 'http' || uri.scheme == 'https' ? uri.origin : null;
  }
}
