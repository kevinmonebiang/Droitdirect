import '../../../../models.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    required super.avatar,
    required super.city,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final payload = (json['user'] as Map<String, dynamic>?) ?? json;
    final roleName = (payload['role'] ?? 'client').toString();

    return AuthUserModel(
      id: (payload['id'] ?? '').toString(),
      fullName: (payload['full_name'] ?? payload['fullName'] ?? '')
          .toString(),
      email: (payload['email'] ?? '').toString(),
      phone: (payload['phone'] ?? '').toString(),
      role: UserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => UserRole.client,
      ),
      avatar: (payload['avatar'] ?? '').toString(),
      city: (payload['city'] ?? '').toString(),
    );
  }
}
