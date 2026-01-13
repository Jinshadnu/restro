import 'package:restro/data/datasources/remote/auth_remote_data_source.dart';
import 'package:restro/data/models/user_model.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:restro/domain/entities/user_entity.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login({
    required String identifier,
    required String password,
  }) async {
    final AppUserModel model = await remoteDataSource.loginUser(
        identifier: identifier, password: password);

    return model.toEntity();
  }

  @override
  Future<UserEntity> loginWithPin(String pin) async {
    final AppUserModel model = await remoteDataSource.loginWithPin(pin);
    return model.toEntity();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<UserEntity> registerUser({
    required String email,
    required String name,
    required String password,
    required String role,
    required String phone,
  }) async {
    final AppUserModel model = await remoteDataSource.registerUser(
      email: email,
      name: name,
      password: password,
      role: role,
      phone: phone,
    );

    return model.toEntity();
  }

  @override
  Future<void> updateUserVerification(String uid) async {
    await remoteDataSource.updateUserVerification(uid);
  }
}
