import 'package:flutter_test/flutter_test.dart';
import 'package:tavola/features/auth/domain/entities/auth_user.dart';
import 'package:tavola/features/auth/domain/entities/restaurant_membership.dart';
import 'package:tavola/features/auth/domain/repositories/auth_repository.dart';
import 'package:tavola/features/auth/domain/usecases/auth_usecases.dart';

void main() {
  test(
    'restaurant onboarding forwards only supplied workspace metadata',
    () async {
      final repository = _AuthRepositorySpy();

      await CreateRestaurant(repository)(
        name: 'La Rosetta',
        timezone: 'Asia/Kolkata',
        restaurantType: 'Café / Bakery',
        phone: '+91 98765 43210',
      );

      expect(repository.restaurantName, 'La Rosetta');
      expect(repository.restaurantType, 'Café / Bakery');
      expect(repository.phone, '+91 98765 43210');
    },
  );

  test(
    'invitation redemption forwards the restaurant and invite codes',
    () async {
      final repository = _AuthRepositorySpy();

      await RedeemRestaurantInvitation(repository)(
        restaurantCode: 'TAV-48291',
        inviteCode: '123456',
      );

      expect(repository.redeemedRestaurantCode, 'TAV-48291');
      expect(repository.redeemedInviteCode, '123456');
    },
  );

  test('profile updates forward the edited name and phone', () async {
    final repository = _AuthRepositorySpy();

    await UpdateProfile(repository)(
      fullName: 'Ayesha Khan',
      phone: '+91 98765 43210',
    );

    expect(repository.profileFullName, 'Ayesha Khan');
    expect(repository.profilePhone, '+91 98765 43210');
  });
}

class _AuthRepositorySpy implements AuthRepository {
  String? restaurantName;
  String? restaurantType;
  String? phone;
  String? redeemedRestaurantCode;
  String? redeemedInviteCode;
  String? profileFullName;
  String? profilePhone;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> createRestaurant({
    required String name,
    required String timezone,
    String? restaurantType,
    String? phone,
  }) async {
    restaurantName = name;
    this.restaurantType = restaurantType;
    this.phone = phone;
  }

  @override
  Future<RestaurantMembership?> getMembership(String userId) async => null;

  @override
  Future<void> redeemRestaurantInvitation({
    required String restaurantCode,
    required String inviteCode,
  }) async {
    redeemedRestaurantCode = restaurantCode;
    redeemedInviteCode = inviteCode;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> verifyStaffPin({
    required String restaurantId,
    required String pin,
  }) async => true;

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    profileFullName = fullName;
    profilePhone = phone;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? restaurantType,
    String? phone,
  }) async {}

  @override
  Stream<AuthUser?> watchAuthUser() => const Stream.empty();
}
