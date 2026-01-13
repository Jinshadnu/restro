import 'package:restro/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> registerUser({
    required String email,
    required String name,
    required String password,
    required String role,
    required String phone,
  });

  Future<UserEntity> login({
    required String identifier,
    required String password,
  });

  Future<UserEntity> loginWithPin(String pin);

  Future<void> logout();

  Future<void> updateUserVerification(String uid);
}
