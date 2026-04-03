import 'package:file_picker/file_picker.dart';

import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  });

  Future<AuthUser> me();

  Future<AuthUser> updateMe({
    String? fullName,
    String? phone,
    String? city,
    PlatformFile? avatarFile,
  });

  Future<void> logout(String refreshToken);
}
