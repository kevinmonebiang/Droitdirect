class ProfessionalReviewEntity {
  const ProfessionalReviewEntity({
    required this.authorName,
    required this.rating,
    required this.comment,
  });

  final String authorName;
  final double rating;
  final String comment;
}

class ProfessionalProfileEntity {
  const ProfessionalProfileEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.professionalNumber,
    required this.professionType,
    required this.city,
    required this.verificationStatus,
    this.interventionZone = '',
    this.bio = '',
    this.address = '',
    this.yearsExperience = 0,
    this.languages = const [],
    this.specialties = const [],
    this.officeName = '',
    this.ratingAverage = 0,
    this.totalReviews = 0,
    this.reviews = const [],
    this.isActive = true,
    this.isOnline = false,
    this.lastSeenAt = '',
    this.isFavorited = false,
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String avatar;
  final String professionalNumber;
  final String professionType;
  final String city;
  final String verificationStatus;
  final String interventionZone;
  final String bio;
  final String address;
  final int yearsExperience;
  final List<String> languages;
  final List<String> specialties;
  final String officeName;
  final double ratingAverage;
  final int totalReviews;
  final List<ProfessionalReviewEntity> reviews;
  final bool isActive;
  final bool isOnline;
  final String lastSeenAt;
  final bool isFavorited;
}
