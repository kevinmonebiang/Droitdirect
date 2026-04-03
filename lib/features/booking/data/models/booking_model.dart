import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.professionalId,
    required super.serviceId,
    required super.status,
    required super.issueTitle,
    required super.issueSummary,
    required super.urgency,
    required super.createdAt,
    required super.paymentStatus,
    required super.bookingType,
    required super.appointmentDate,
    required super.startTime,
    required super.endTime,
    required super.amount,
    required super.meetingLink,
    required super.onsiteAddress,
    required super.note,
    required super.serviceTitle,
    required super.clientName,
    required super.professionalName,
    required super.conversationId,
    required super.paymentId,
    required super.issueReportStatus,
    required super.hasReview,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'].toString(),
      userId: json['user'].toString(),
      professionalId: json['professional'].toString(),
      serviceId: json['service'].toString(),
      status: (json['status'] ?? '') as String,
      issueTitle: (json['issue_title'] ?? json['issueTitle'] ?? '') as String,
      issueSummary:
          (json['issue_summary'] ?? json['issueSummary'] ?? '') as String,
      urgency: (json['urgency'] ?? '') as String,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '') as String,
      paymentStatus: (json['payment_status'] ?? json['paymentStatus'] ?? '')
          as String,
      bookingType: (json['booking_type'] ?? json['bookingType'] ?? '') as String,
      appointmentDate:
          (json['appointment_date'] ?? json['appointmentDate'] ?? '') as String,
      startTime: (json['start_time'] ?? json['startTime'] ?? '') as String,
      endTime: (json['end_time'] ?? json['endTime'] ?? '') as String,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      meetingLink: (json['meeting_link'] ?? json['meetingLink'] ?? '') as String,
      onsiteAddress:
          (json['onsite_address'] ?? json['onsiteAddress'] ?? '') as String,
      note: (json['note'] ?? '') as String,
      serviceTitle: (json['service_title'] ?? '').toString(),
      clientName: (json['client_name'] ?? '').toString(),
      professionalName: (json['professional_name'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      paymentId: (json['payment_id'] ?? '').toString(),
      issueReportStatus: (json['issue_report_status'] ?? '').toString(),
      hasReview: (json['has_review'] ?? false) == true,
    );
  }
}
