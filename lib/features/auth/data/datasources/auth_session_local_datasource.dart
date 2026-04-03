import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

class AuthSessionLocalDataSource {
  static const _storageKey = 'camrlex_auth_session';

  Future<void> saveSession(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'access': session.accessToken,
      'refresh': session.refreshToken,
        'user': {
          'id': session.user.id,
          'full_name': session.user.fullName,
          'email': session.user.email,
          'phone': session.user.phone,
          'role': session.user.role.name,
          'avatar': session.user.avatar,
          'city': session.user.city,
        },
      };
    await preferences.setString(_storageKey, jsonEncode(payload));
  }

  Future<AuthSession?> readSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }

      final userPayload = decoded['user'];
      if (userPayload is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }

      final roleName = (userPayload['role'] ?? 'client').toString();
      final role = UserRole.values.firstWhere(
        (item) => item.name == roleName,
        orElse: () => UserRole.client,
      );

      final accessToken = (decoded['access'] ?? '').toString();
      final refreshToken = (decoded['refresh'] ?? '').toString();
      if (accessToken.isEmpty || refreshToken.isEmpty) {
        await clearSession();
        return null;
      }

      return AuthSession(
        user: AuthUser(
          id: (userPayload['id'] ?? '').toString(),
          fullName: (userPayload['full_name'] ?? '').toString(),
          email: (userPayload['email'] ?? '').toString(),
          phone: (userPayload['phone'] ?? '').toString(),
          role: role,
          avatar: (userPayload['avatar'] ?? '').toString(),
          city: (userPayload['city'] ?? '').toString(),
        ),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
