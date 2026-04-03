import 'package:dio/dio.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }
      return data as List<dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/notifications/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> markRead(String notificationId) async {
    try {
      final response = await _dio.put('/notifications/$notificationId/read');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.put('/notifications/$notificationId/read/');
    return fallback.data as Map<String, dynamic>;
  }
}
