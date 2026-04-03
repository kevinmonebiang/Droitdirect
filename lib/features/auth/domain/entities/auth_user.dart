import '../../../../models.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar = '',
    this.city = '',
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String avatar;
  final String city;
}
