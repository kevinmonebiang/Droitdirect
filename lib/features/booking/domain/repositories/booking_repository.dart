import '../entities/booking_entity.dart';
import '../entities/availability_slot_entity.dart';

abstract class BookingRepository {
  Future<List<BookingEntity>> listBookings();
  Future<List<AvailabilitySlotEntity>> listAvailabilitySlots({
    String professionalId = '',
  });
  Future<AvailabilitySlotEntity> createAvailabilitySlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  });
  Future<AvailabilitySlotEntity> updateAvailabilitySlot({
    required String slotId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required int slotDuration,
    bool isAvailable = true,
  });
  Future<void> deleteAvailabilitySlot(String slotId);
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
  });
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String action,
    Map<String, dynamic> data = const {},
  });
  Future<Map<String, dynamic>> reportIssue({
    required String bookingId,
    required String reason,
    required String details,
    required bool wantsRefund,
  });
  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String provider,
    required double amount,
  });
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentId,
  });
  Future<List<int>> downloadReceipt(String paymentId);
}
