import '../entities/service_offer_entity.dart';
import '../repositories/services_repository.dart';

class ListServicesUseCase {
  const ListServicesUseCase(this._repository);

  final ServicesRepository _repository;

  Future<List<ServiceOfferEntity>> call() {
    return _repository.listServices();
  }
}
