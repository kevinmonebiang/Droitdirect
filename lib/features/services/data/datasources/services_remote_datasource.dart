import 'package:dio/dio.dart';

class ServicesRemoteDataSource {
  const ServicesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listServices() async {
    try {
      final response = await _dio.get('/services');
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

    final fallback = await _dio.get('/services/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getService(String id) async {
    try {
      final response = await _dio.get('/services/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/services/$id/');
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createService({
    required String title,
    required String description,
    required String mode,
    required String priceType,
    required double amount,
    required int durationMinutes,
    required String city,
    String address = '',
    String currency = 'XAF',
    bool isPublished = false,
    String categoryInput = '',
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'mode': mode,
      'price_type': priceType,
      'amount': amount,
      'currency': currency,
      'duration_minutes': durationMinutes,
      'city': city,
      'address': address,
      'is_published': isPublished,
      'category_input': categoryInput,
    };

    try {
      final response = await _dio
          .post(
            '/services',
            data: payload,
          )
          .timeout(const Duration(seconds: 25));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .post(
          '/services/',
          data: payload,
        )
        .timeout(const Duration(seconds: 25));
    return fallback.data as Map<String, dynamic>;
  }
}
