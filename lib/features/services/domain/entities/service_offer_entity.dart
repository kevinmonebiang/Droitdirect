class ServiceOfferEntity {
  const ServiceOfferEntity({
    required this.id,
    required this.professionalId,
    required this.title,
    required this.amount,
    required this.mode,
    this.priceType = 'fixed',
    this.description = '',
    this.category = '',
    this.city = '',
    this.address = '',
    this.currency = 'XAF',
    this.durationMinutes = 0,
    this.isPublished = false,
  });

  final String id;
  final String professionalId;
  final String title;
  final double amount;
  final String mode;
  final String priceType;
  final String description;
  final String category;
  final String city;
  final String address;
  final String currency;
  final int durationMinutes;
  final bool isPublished;
}
