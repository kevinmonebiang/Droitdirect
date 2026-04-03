import '../../domain/entities/service_offer_entity.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';
import '../models/service_offer_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  const ServicesRepositoryImpl(this._remoteDataSource);

  final ServicesRemoteDataSource _remoteDataSource;

  @override
  Future<List<ServiceOfferEntity>> listServices() async {
    final items = await _remoteDataSource.listServices();
    return items
        .map((item) => ServiceOfferModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ServiceOfferEntity> getService(String id) async {
    final json = await _remoteDataSource.getService(id);
    return ServiceOfferModel.fromJson(json);
  }

  @override
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
  }) async {
    final json = await _remoteDataSource.createService(
      title: title,
      description: description,
      mode: mode,
      priceType: priceType,
      amount: amount,
      durationMinutes: durationMinutes,
      city: city,
      address: address,
      currency: currency,
      isPublished: isPublished,
      categoryInput: categoryInput,
    );
    return ServiceOfferModel.fromJson(json);
  }
}
