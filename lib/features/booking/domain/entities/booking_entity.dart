class BookingEntity {
  const BookingEntity({
    required this.id,
    required this.userId,
    required this.professionalId,
    required this.serviceId,
    required this.status,
    this.issueTitle = '',
    this.issueSummary = '',
    this.urgency = '',
    this.createdAt = '',
    this.paymentStatus = '',
    this.bookingType = '',
    this.appointmentDate = '',
    this.startTime = '',
    this.endTime = '',
    this.amount = 0,
    this.meetingLink = '',
    this.onsiteAddress = '',
    this.note = '',
    this.serviceTitle = '',
    this.clientName = '',
    this.professionalName = '',
    this.conversationId = '',
    this.paymentId = '',
    this.issueReportStatus = '',
    this.hasReview = false,
  });

  final String id;
  final String userId;
  final String professionalId;
  final String serviceId;
  final String status;
  final String issueTitle;
  final String issueSummary;
  final String urgency;
  final String createdAt;
  final String paymentStatus;
  final String bookingType;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final double amount;
  final String meetingLink;
  final String onsiteAddress;
  final String note;
  final String serviceTitle;
  final String clientName;
  final String professionalName;
  final String conversationId;
  final String paymentId;
  final String issueReportStatus;
  final bool hasReview;
}
