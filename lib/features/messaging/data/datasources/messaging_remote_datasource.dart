import 'package:dio/dio.dart';

class MessagingRemoteDataSource {
  const MessagingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listConversations() async {
    try {
      final response = await _dio.get('/conversations');
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

    final fallback = await _dio.get('/conversations/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    final payload = {
      'conversation': conversationId,
      'content': content,
      'message_type': messageType,
    };
    try {
      final response = await _dio.post(
        '/messages',
        data: payload,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.post(
      '/messages/',
      data: payload,
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<void> markConversationRead(String conversationId) async {
    try {
      await _dio.post('/conversations/$conversationId/mark_read');
      return;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }
    await _dio.post('/conversations/$conversationId/mark_read/');
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await _dio.post('/conversations/$conversationId/archive');
      return;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }
    await _dio.post('/conversations/$conversationId/archive/');
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.post('/conversations/$conversationId/delete');
      return;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }
    await _dio.post('/conversations/$conversationId/delete/');
  }
}
