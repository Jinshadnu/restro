import 'package:restro/data/datasources/remote/auth_remote_data_source.dart';
import 'package:restro/data/models/user_model.dart';
import 'package:restro/data/repositories/auth_repository.dart';
import 'package:restro/domain/entities/user_entity.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final AppUserModel model =
    await remoteDataSource.loginUser(email: email, password: password);

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
      password: password,
      name: name,
      phone: phone,
      role: role,
    );

    return model.toEntity();
  }
}