import 'package:dio/dio.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getOverview() async {
    final response = await _dio.get('/admin/overview');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewProfessional({
    required String professionalId,
    required String status,
    String rejectionReason = '',
  }) async {
    final response = await _dio.put(
      '/professionals/$professionalId/review-verification',
      data: {
        'status': status,
        'rejection_reason': rejectionReason,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewIssueReport({
    required String bookingId,
    required String status,
    String adminNote = '',
  }) async {
    final response = await _dio.put(
      '/bookings/$bookingId/review-issue',
      data: {
        'status': status,
        'admin_note': adminNote,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
