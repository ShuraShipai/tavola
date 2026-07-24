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
  }) =>
      _repository.signUp(email: email, password: password, fullName: fullName);
}

class CreateRestaurant {
  const CreateRestaurant(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String name, required String timezone}) =>
      _repository.createRestaurant(name: name, timezone: timezone);
}
