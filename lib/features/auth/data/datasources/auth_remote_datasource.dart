import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
    String city = '',
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role,
        'city': city,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get('/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/me/');
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMe({
    String? fullName,
    String? phone,
    String? city,
    PlatformFile? avatarFile,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) {
      payload['full_name'] = fullName;
    }
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (city != null) {
      payload['city'] = city;
    }

    try {
      final response = avatarFile == null
          ? await _dio
              .patch(
                '/me',
                data: payload,
              )
              .timeout(const Duration(seconds: 12))
          : await _dio
              .patch(
                '/me',
                data: FormData.fromMap({
                  ...payload,
                  'avatar_file': await _multipartFromPlatformFile(avatarFile),
                }),
                options: Options(contentType: 'multipart/form-data'),
              )
              .timeout(const Duration(seconds: 30));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = avatarFile == null
        ? await _dio
            .patch(
              '/me/',
              data: payload,
            )
            .timeout(const Duration(seconds: 12))
        : await _dio
            .patch(
              '/me/',
              data: FormData.fromMap({
                ...payload,
                'avatar_file': await _multipartFromPlatformFile(avatarFile),
              }),
              options: Options(contentType: 'multipart/form-data'),
            )
            .timeout(const Duration(seconds: 30));
    return fallback.data as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      '/auth/logout',
      data: {'refresh': refreshToken},
    );
  }

  Future<MultipartFile> _multipartFromPlatformFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }
    throw ArgumentError('Le fichier selectionne est invalide.');
  }
}
