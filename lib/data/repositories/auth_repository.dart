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
    required String email,
    required String password,
  });

  Future<void> logout();
}