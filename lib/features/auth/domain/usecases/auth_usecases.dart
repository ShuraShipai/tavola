import '../repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}

class SignUp {
  const SignUp(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String password,
    required String fullName,
    String? restaurantType,
    String? phone,
  }) => _repository.signUp(
    email: email,
    password: password,
    fullName: fullName,
    restaurantType: restaurantType,
    phone: phone,
  );
}

class CreateRestaurant {
  const CreateRestaurant(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String timezone,
    String? restaurantType,
    String? phone,
  }) => _repository.createRestaurant(
    name: name,
    timezone: timezone,
    restaurantType: restaurantType,
    phone: phone,
  );
}

class RedeemRestaurantInvitation {
  const RedeemRestaurantInvitation(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String restaurantCode,
    required String inviteCode,
  }) => _repository.redeemRestaurantInvitation(
    restaurantCode: restaurantCode,
    inviteCode: inviteCode,
  );
}

class UpdateProfile {
  const UpdateProfile(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String fullName, String? phone}) =>
      _repository.updateProfile(fullName: fullName, phone: phone);
}
