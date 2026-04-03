import 'package:dio/dio.dart';

class ReviewsRemoteDataSource {
  const ReviewsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    final response = await _dio.post(
      '/reviews',
      data: {
        'booking': bookingId,
        'rating': rating,
        'comment': comment,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
