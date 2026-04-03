import '../../domain/entities/professional_profile_entity.dart';

class ProfessionalProfileModel extends ProfessionalProfileEntity {
  const ProfessionalProfileModel({
    required super.id,
    required super.userId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.avatar,
    required super.professionalNumber,
    required super.professionType,
    required super.city,
    required super.verificationStatus,
    required super.interventionZone,
    required super.bio,
    required super.address,
    required super.yearsExperience,
    required super.languages,
    required super.specialties,
    required super.officeName,
    required super.ratingAverage,
    required super.totalReviews,
    required super.reviews,
    required super.isActive,
    required super.isOnline,
    required super.lastSeenAt,
    required super.isFavorited,
  });

  factory ProfessionalProfileModel.fromJson(Map<String, dynamic> json) {
    final rawLanguages = (json['languages'] as List<dynamic>?) ?? const [];
    final rawSpecialties =
        (json['specialties'] as List<dynamic>?) ?? const [];
    final rawReviews = (json['reviews'] as List<dynamic>?) ?? const [];

    return ProfessionalProfileModel(
      id: json['id'].toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      professionalNumber:
          (json['professional_number'] ?? json['professionalNumber'] ?? '')
              .toString(),
      professionType: (json['profession_type'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      verificationStatus: (json['verification_status'] ?? '') as String,
      interventionZone:
          (json['intervention_zone'] ?? json['interventionZone'] ?? '')
              .toString(),
      bio: (json['bio'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      yearsExperience: int.tryParse(
            (json['years_experience'] ?? json['yearsExperience'] ?? 0)
                .toString(),
          ) ??
          0,
      languages: rawLanguages.map((item) => item.toString()).toList(),
      specialties: rawSpecialties.map((item) => item.toString()).toList(),
      officeName: (json['office_name'] ?? json['officeName'] ?? '') as String,
      ratingAverage:
          double.tryParse((json['rating_average'] ?? 0).toString()) ?? 0,
      totalReviews:
          int.tryParse((json['total_reviews'] ?? 0).toString()) ?? 0,
      reviews: rawReviews
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ProfessionalReviewEntity(
              authorName: (item['author_name'] ?? '').toString(),
              rating: double.tryParse((item['rating'] ?? 0).toString()) ?? 0,
              comment: (item['comment'] ?? '').toString(),
            ),
          )
          .toList(),
      isActive: (json['is_active'] ?? true) == true,
      isOnline: (json['is_online'] ?? false) == true,
      lastSeenAt: (json['last_seen_at'] ?? '').toString(),
      isFavorited: (json['is_favorited'] ?? false) == true,
    );
  }
}
