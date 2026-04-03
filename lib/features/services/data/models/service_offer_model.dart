import '../../domain/entities/service_offer_entity.dart';

class ServiceOfferModel extends ServiceOfferEntity {
  const ServiceOfferModel({
    required super.id,
    required super.professionalId,
    required super.title,
    required super.amount,
    required super.mode,
    required super.priceType,
    required super.description,
    required super.category,
    required super.city,
    required super.address,
    required super.currency,
    required super.durationMinutes,
    required super.isPublished,
  });

  factory ServiceOfferModel.fromJson(Map<String, dynamic> json) {
    return ServiceOfferModel(
      id: json['id'].toString(),
      professionalId: json['professional'].toString(),
      title: (json['title'] ?? '') as String,
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      mode: (json['mode'] ?? '') as String,
      priceType: (json['price_type'] ?? json['priceType'] ?? 'fixed').toString(),
      description: (json['description'] ?? '') as String,
      category: (json['category_name'] ?? json['category'] ?? '').toString(),
      city: (json['city'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      currency: (json['currency'] ?? 'XAF') as String,
      durationMinutes: int.tryParse(
            (json['duration_minutes'] ?? json['durationMinutes'] ?? 0)
                .toString(),
          ) ??
          0,
      isPublished: (json['is_published'] ?? json['isPublished'] ?? false) ==
          true,
    );
  }
}
