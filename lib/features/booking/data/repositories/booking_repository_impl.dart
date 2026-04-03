import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/availability_slot_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/availability_slot_model.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this._remoteDataSource);

  final BookingRemoteDataSource _remoteDataSource;

  @override
  Future<List<BookingEntity>> listBookings() async {
    final items = await _remoteDataSource.listBookings();
    return items
        .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AvailabilitySlotEntity>> listAvailabilitySlots({
    String professionalId = '',
  }) async {
    final items = await _remoteDataSource.listAvailabilitySlots(
      professionalId: professionalId,
    );
    return items
        .map(
          (item) =>
              AvailabilitySlotModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<AvailabilitySlotEntity> createAvailabilitySlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  }) async {
    final json = await _remoteDataSource.createAvailabilitySlot(
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      slotDuration: slotDuration,
      isAvailable: isAvailable,
    );
    return AvailabilitySlotModel.fromJson(json);
  }

  @override
  Future<AvailabilitySlotEntity> updateAvailabilitySlot({
    required String slotId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  }) async {
    final json = await _remoteDataSource.updateAvailabilitySlot(
      slotId: slotId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      slotDuration: slotDuration,
      isAvailable: isAvailable,
    );
    return AvailabilitySlotModel.fromJson(json);
  }

  @override
  Future<void> deleteAvailabilitySlot(String slotId) {
    return _remoteDataSource.deleteAvailabilitySlot(slotId);
  }

  @override
  Future<BookingEntity> createBooking({
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
    final json = await _remoteDataSource.createBooking(
      serviceId: serviceId,
      bookingType: bookingType,
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
      issueTitle: issueTitle,
      issueSummary: issueSummary,
      urgency: urgency,
      note: note,
    );
    return BookingModel.fromJson(json);
  }

  @override
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String action,
    Map<String, dynamic> data = const {},
  }) async {
    final json = await _remoteDataSource.updateBookingStatus(
      bookingId: bookingId,
      action: action,
      data: data,
    );
    return BookingModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> reportIssue({
    required String bookingId,
    required String reason,
    required String details,
    required bool wantsRefund,
  }) {
    return _remoteDataSource.reportIssue(
      bookingId: bookingId,
      reason: reason,
      details: details,
      wantsRefund: wantsRefund,
    );
  }

  @override
  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String provider,
    required double amount,
  }) {
    return _remoteDataSource.initiatePayment(
      bookingId: bookingId,
      provider: provider,
      amount: amount,
    );
  }

  @override
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
  }) {
    return _remoteDataSource.confirmPayment(paymentId: paymentId);
  }

  @override
  Future<List<int>> downloadReceipt(String paymentId) {
    return _remoteDataSource.downloadReceipt(paymentId);
  }
}
