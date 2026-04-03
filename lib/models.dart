enum UserRole { client, professional, admin }

enum LegalProfession { avocat, huissier, notaire }

enum ServiceMode { inPerson, online, both }

enum VerificationStatus {
  draft,
  submitted,
  underReview,
  verified,
  rejected,
  needsCompletion,
  suspended,
}

enum BookingStatus {
  pending,
  accepted,
  refused,
  cancelled,
  completed,
  expired,
  disputed,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum PaymentProvider {
  orangeMoney,
  mtnMoney,
}

enum BookingUrgency {
  urgent,
  medium,
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.client:
        return 'Utilisateur';
      case UserRole.professional:
        return 'Professionnel';
      case UserRole.admin:
        return 'Administrateur';
    }
  }
}

extension LegalProfessionLabel on LegalProfession {
  String get label {
    switch (this) {
      case LegalProfession.avocat:
        return 'Avocat';
      case LegalProfession.huissier:
        return 'Huissier';
      case LegalProfession.notaire:
        return 'Notaire';
    }
  }
}

extension ServiceModeLabel on ServiceMode {
  String get label {
    switch (this) {
      case ServiceMode.inPerson:
        return 'Presentiel';
      case ServiceMode.online:
        return 'En ligne';
      case ServiceMode.both:
        return 'Les deux';
    }
  }
}

extension VerificationStatusLabel on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.draft:
        return 'Brouillon';
      case VerificationStatus.submitted:
        return 'Soumis';
      case VerificationStatus.underReview:
        return 'En cours d examen';
      case VerificationStatus.verified:
        return 'Verifie';
      case VerificationStatus.rejected:
        return 'Rejete';
      case VerificationStatus.needsCompletion:
        return 'A completer';
      case VerificationStatus.suspended:
        return 'Suspendu';
    }
  }
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.accepted:
        return 'Acceptee';
      case BookingStatus.refused:
        return 'Refusee';
      case BookingStatus.cancelled:
        return 'Annulee';
      case BookingStatus.completed:
        return 'Terminee';
      case BookingStatus.expired:
        return 'Expiree';
      case BookingStatus.disputed:
        return 'Litige';
    }
  }
}

extension PaymentStatusLabel on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Paiement en attente';
      case PaymentStatus.paid:
        return 'Paye';
      case PaymentStatus.failed:
        return 'Paiement echoue';
      case PaymentStatus.refunded:
        return 'Rembourse';
    }
  }
}

extension PaymentProviderLabel on PaymentProvider {
  String get label {
    switch (this) {
      case PaymentProvider.orangeMoney:
        return 'Orange Money';
      case PaymentProvider.mtnMoney:
        return 'MTN Mobile Money';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentProvider.orangeMoney:
        return 'orange_money';
      case PaymentProvider.mtnMoney:
        return 'mtn_money';
    }
  }
}

extension BookingUrgencyLabel on BookingUrgency {
  String get label {
    switch (this) {
      case BookingUrgency.urgent:
        return 'Urgent';
      case BookingUrgency.medium:
        return 'Moyen';
    }
  }

  String get apiValue {
    switch (this) {
      case BookingUrgency.urgent:
        return 'urgent';
      case BookingUrgency.medium:
        return 'medium';
    }
  }
}

class Review {
  const Review({
    required this.authorName,
    required this.rating,
    required this.comment,
  });

  final String authorName;
  final double rating;
  final String comment;
}

class ProfessionalProfile {
  const ProfessionalProfile({
    required this.fullName,
    required this.profession,
    required this.professionalNumber,
    required this.verificationStatus,
    required this.city,
    required this.interventionZone,
    required this.languages,
    required this.bio,
    required this.specialties,
    required this.yearsExperience,
    required this.officeName,
    required this.address,
    required this.averageRating,
    required this.reviews,
    required this.canReceiveBookings,
    this.avatarUrl = '',
    this.isOnline = false,
    this.lastSeenLabel = '',
    this.isFavorited = false,
  });

  final String fullName;
  final LegalProfession profession;
  final String professionalNumber;
  final VerificationStatus verificationStatus;
  final String city;
  final String interventionZone;
  final List<String> languages;
  final String bio;
  final List<String> specialties;
  final int yearsExperience;
  final String officeName;
  final String address;
  final double averageRating;
  final List<Review> reviews;
  final bool canReceiveBookings;
  final String avatarUrl;
  final bool isOnline;
  final String lastSeenLabel;
  final bool isFavorited;
}

class ServiceOffer {
  const ServiceOffer({
    required this.id,
    required this.profile,
    required this.title,
    required this.description,
    required this.category,
    required this.mode,
    required this.feeCfa,
    required this.durationLabel,
    required this.requiredDocuments,
    required this.executionDelay,
    required this.city,
    required this.instantBooking,
    required this.isPublished,
    this.priceType = 'fixed',
    this.professionalId = '',
  });

  final String id;
  final ProfessionalProfile profile;
  final String title;
  final String description;
  final String category;
  final ServiceMode mode;
  final int feeCfa;
  final String durationLabel;
  final List<String> requiredDocuments;
  final String executionDelay;
  final String city;
  final bool instantBooking;
  final bool isPublished;
  final String priceType;
  final String professionalId;

  bool get isFree => priceType == 'fixed' && feeCfa <= 0;
  bool get isPricedAfterReview => priceType == 'negotiable';

  String get pricingLabel {
    if (isFree) {
      return 'Gratuit';
    }
    if (isPricedAfterReview) {
      return 'Selon dossier';
    }
    return '$feeCfa FCFA';
  }
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.professionalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDuration,
    this.isAvailable = true,
  });

  final String id;
  final String professionalId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDuration;
  final bool isAvailable;
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.clientName,
    required this.serviceTitle,
    required this.professionalName,
    required this.mode,
    required this.dateLabel,
    required this.priceCfa,
    required this.status,
    required this.paymentStatus,
    required this.locationLabel,
    this.urgency = BookingUrgency.medium,
    this.createdAt = '',
    this.issueTitle = '',
    this.issueSummary = '',
    this.conversationId = '',
    this.paymentId = '',
    this.issueReportStatus = '',
    this.hasReview = false,
  });

  final String id;
  final String clientName;
  final String serviceTitle;
  final String professionalName;
  final ServiceMode mode;
  final String dateLabel;
  final int priceCfa;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String locationLabel;
  final BookingUrgency urgency;
  final String createdAt;
  final String issueTitle;
  final String issueSummary;
  final String conversationId;
  final String paymentId;
  final String issueReportStatus;
  final bool hasReview;
}

class PaymentInstruction {
  const PaymentInstruction({
    required this.paymentId,
    required this.provider,
    required this.ussdCode,
  });

  final String paymentId;
  final PaymentProvider provider;
  final String ussdCode;
}

class AdminMetric {
  const AdminMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class ChatMessage {
  const ChatMessage({
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.isMine,
    required this.isRead,
    this.attachmentLabel,
  });

  final String senderName;
  final String message;
  final String sentAt;
  final bool isMine;
  final bool isRead;
  final String? attachmentLabel;
}

class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.contactName,
    required this.subtitle,
    required this.unreadCount,
    required this.lastActivityAt,
    required this.messages,
  });

  final String id;
  final String contactName;
  final String subtitle;
  final int unreadCount;
  final String lastActivityAt;
  final List<ChatMessage> messages;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timeLabel,
    required this.isUnread,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String timeLabel;
  final bool isUnread;
}

class FavoriteProfessional {
  const FavoriteProfessional({
    required this.id,
    required this.professionalId,
    required this.fullName,
    required this.profession,
    required this.city,
    required this.avatarUrl,
  });

  final String id;
  final String professionalId;
  final LegalProfession profession;
  final String fullName;
  final String city;
  final String avatarUrl;
}
