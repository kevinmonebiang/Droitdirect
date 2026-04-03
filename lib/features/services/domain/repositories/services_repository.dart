import '../entities/service_offer_entity.dart';

abstract class ServicesRepository {
  Future<List<ServiceOfferEntity>> listServices();
  Future<ServiceOfferEntity> getService(String id);
  Future<ServiceOfferEntity> createService({
    required String title,
    required String description,
    required String mode,
    required String priceType,
    required double amount,
    required int durationMinutes,
    required String city,
    String address = '',
    String currency = 'XAF',
    bool isPublished = false,
    String categoryInput = '',
  });
}
