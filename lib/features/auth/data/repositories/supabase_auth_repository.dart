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
  Stream<AuthUser?> watchAuthUser() async* {
    // Emit the current session immediately. Waiting only for an auth event can
    // briefly make a valid session look signed out while the router starts.
    yield await _loadProfile(currentUser);
    await for (final state in _client.auth.onAuthStateChange) {
      yield await _loadProfile(_mapUser(state.session?.user));
    }
  }

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
    String? restaurantType,
    String? phone,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        // ignore: use_null_aware_elements
        if (restaurantType case final type?) 'restaurant_type': type,
        if (phone case final value? when value.trim().isNotEmpty)
          'phone': value.trim(),
      },
      emailRedirectTo: _webRedirectUrl,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to edit a profile.');
    }
    final normalizedPhone = phone?.trim();
    await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': normalizedPhone?.isEmpty ?? true ? null : normalizedPhone,
        })
        .eq('id', user.id);
  }

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
        .order('created_at')
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
    String? restaurantType,
    String? phone,
  }) async {
    await _client.rpc(
      'complete_restaurant_onboarding',
      params: {
        'p_name': name.trim(),
        'p_restaurant_type': restaurantType?.trim(),
        'p_phone': phone?.trim(),
        'p_timezone': timezone,
      },
    );
  }

  @override
  Future<void> redeemRestaurantInvitation({
    required String restaurantCode,
    required String inviteCode,
  }) => _client.rpc(
    'redeem_restaurant_invitation',
    params: {
      'p_restaurant_code': restaurantCode.trim(),
      'p_invite_code': inviteCode.trim(),
    },
  );

  @override
  Future<bool> verifyStaffPin({
    required String restaurantId,
    required String pin,
  }) async {
    final result = await _client.rpc(
      'verify_staff_pin',
      params: {'p_restaurant_id': restaurantId, 'p_pin': pin},
    );
    return result == true;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null || user.email == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email!,
      fullName:
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
      phone: user.userMetadata?['phone'] as String?,
      pendingRestaurantType: user.userMetadata?['restaurant_type'] as String?,
      pendingPhone: user.userMetadata?['phone'] as String?,
    );
  }

  AuthUser _withProfile(AuthUser user, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return user;
    final profile = rows.first;
    return AuthUser(
      id: user.id,
      email: profile['email'] as String? ?? user.email,
      fullName: profile['full_name'] as String? ?? user.fullName,
      phone: profile['phone'] as String? ?? user.phone,
      pendingRestaurantType: user.pendingRestaurantType,
      pendingPhone: user.pendingPhone,
    );
  }

  Future<AuthUser?> _loadProfile(AuthUser? user) async {
    if (user == null) return null;
    try {
      final rows = await _client
          .from('profiles')
          .select('email, full_name, phone')
          .eq('id', user.id)
          .limit(1);
      return _withProfile(
        user,
        (rows as List<dynamic>).cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      // Auth state remains usable when profile enrichment is temporarily
      // unavailable; the profile can be refreshed on the next auth event.
      return user;
    }
  }

  String? get _webRedirectUrl {
    final uri = Uri.base;
    return uri.scheme == 'http' || uri.scheme == 'https' ? uri.origin : null;
  }
}
