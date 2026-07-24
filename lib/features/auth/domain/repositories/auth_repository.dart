import '../entities/auth_user.dart';
import '../entities/restaurant_membership.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthUser();
  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<RestaurantMembership?> getMembership(String userId);
  Future<void> createRestaurant({
    required String name,
    required String timezone,
  });
}
