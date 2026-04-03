import 'package:file_picker/file_picker.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json =
        await _remoteDataSource.login(email: email, password: password);
    return AuthSessionModel.fromJson(json);
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    await _remoteDataSource.register(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      role: role,
    );
    return login(email: email, password: password);
  }

  @override
  Future<AuthUser> me() async {
    final json = await _remoteDataSource.me();
    return AuthUserModel.fromJson(json);
  }

  @override
  Future<AuthUser> updateMe({
    String? fullName,
    String? phone,
    String? city,
    PlatformFile? avatarFile,
  }) async {
    final json = await _remoteDataSource.updateMe(
      fullName: fullName,
      phone: phone,
      city: city,
      avatarFile: avatarFile,
    );
    return AuthUserModel.fromJson(json);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _remoteDataSource.logout(refreshToken);
  }
}
