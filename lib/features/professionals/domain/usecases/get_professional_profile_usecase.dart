import '../entities/professional_profile_entity.dart';
import '../repositories/professionals_repository.dart';

class GetProfessionalProfileUseCase {
  const GetProfessionalProfileUseCase(this._repository);

  final ProfessionalsRepository _repository;

  Future<ProfessionalProfileEntity> call(String id) {
    return _repository.getProfessional(id);
  }
}
