import 'package:dio/dio.dart';

class BookingRemoteDataSource {
  const BookingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listBookings() async {
    try {
      final response = await _dio.get('/bookings');
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

    final fallback = await _dio.get('/bookings/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<List<dynamic>> listAvailabilitySlots({
    String professionalId = '',
  }) async {
    final query = {
      if (professionalId.isNotEmpty) 'professional': professionalId,
    };

    try {
      final response = await _dio.get(
        '/availability-slots',
        queryParameters: query,
      );
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

    final fallback = await _dio.get(
      '/availability-slots/',
      queryParameters: query,
    );
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAvailabilitySlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  }) async {
    final payload = {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration': slotDuration,
      'is_available': isAvailable,
    };

    try {
      final response = await _dio
          .post(
            '/availability-slots',
            data: payload,
          )
          .timeout(const Duration(seconds: 20));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .post(
          '/availability-slots/',
          data: payload,
        )
        .timeout(const Duration(seconds: 20));
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAvailabilitySlot({
    required String slotId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  }) async {
    final payload = {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration': slotDuration,
      'is_available': isAvailable,
    };

    try {
      final response = await _dio
          .put(
            '/availability-slots/$slotId',
            data: payload,
          )
          .timeout(const Duration(seconds: 20));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .put(
          '/availability-slots/$slotId/',
          data: payload,
        )
        .timeout(const Duration(seconds: 20));
    return fallback.data as Map<String, dynamic>;
  }

  Future<void> deleteAvailabilitySlot(String slotId) async {
    try {
      await _dio.delete('/availability-slots/$slotId');
      return;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }
    await _dio.delete('/availability-slots/$slotId/');
  }

  Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String bookingType,
    required String appointmentDate,
    required String startTime,
    required String endTime,
    required String issueTitle,
    required String issueSummary,
    required String urgency,
    String note = '',
  }) async {
    final payload = {
      'service': serviceId,
      'issue_title': issueTitle,
      'issue_summary': issueSummary,
      'urgency': urgency,
      'booking_type': bookingType,
      'appointment_date': appointmentDate,
      'start_time': startTime,
      'end_time': endTime,
      'note': note,
    };
    try {
      final response = await _dio.post(
        '/bookings',
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
      '/bookings/',
      data: payload,
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String action,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final response = await _dio.put(
        '/bookings/$bookingId/$action',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.put(
      '/bookings/$bookingId/$action/',
      data: data,
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reportIssue({
    required String bookingId,
    required String reason,
    required String details,
    required bool wantsRefund,
  }) async {
    final payload = {
      'reason': reason,
      'details': details,
      'wants_refund': wantsRefund,
    };
    try {
      final response = await _dio.post(
        '/bookings/$bookingId/report-issue',
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
      '/bookings/$bookingId/report-issue/',
      data: payload,
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String provider,
    required double amount,
  }) async {
    final payload = {
      'booking': bookingId,
      'provider': provider,
      'amount': amount,
      'currency': 'XAF',
    };
    try {
      final response = await _dio.post(
        '/payments/initiate',
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
      '/payments/initiate/',
      data: payload,
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/confirm',
        data: {'payment_id': paymentId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.post(
      '/payments/confirm/',
      data: {'payment_id': paymentId},
    );
    return fallback.data as Map<String, dynamic>;
  }

  Future<List<int>> downloadReceipt(String paymentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/payments/$paymentId/receipt',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const <int>[];
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get<List<int>>(
      '/payments/$paymentId/receipt/',
      options: Options(responseType: ResponseType.bytes),
    );
    return fallback.data ?? const <int>[];
  }
}
