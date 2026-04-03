import 'package:file_picker/file_picker.dart';

import '../../domain/entities/professional_profile_entity.dart';
import '../../domain/repositories/professionals_repository.dart';
import '../datasources/professionals_remote_datasource.dart';
import '../models/professional_profile_model.dart';

class ProfessionalsRepositoryImpl implements ProfessionalsRepository {
  const ProfessionalsRepositoryImpl(this._remoteDataSource);

  final ProfessionalsRemoteDataSource _remoteDataSource;

  @override
  Future<ProfessionalProfileEntity> getProfessional(String id) async {
    final json = await _remoteDataSource.getProfessional(id);
    return ProfessionalProfileModel.fromJson(json);
  }

  @override
  Future<ProfessionalProfileEntity?> getMyProfessionalProfile() async {
    final json = await _remoteDataSource.getMyProfessionalProfile();
    if (json == null) {
      return null;
    }
    return ProfessionalProfileModel.fromJson(json);
  }

  @override
  Future<List<ProfessionalProfileEntity>> listProfessionals() async {
    final items = await _remoteDataSource.listProfessionals();
    return items
        .map((item) =>
            ProfessionalProfileModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProfessionalProfileEntity> createProfessionalProfile({
    required String professionType,
    String professionalNumber = '',
    required String city,
    required String bio,
    String interventionZone = '',
    String address = '',
    int yearsExperience = 0,
    List<String> languages = const [],
    List<String> specialties = const [],
    String officeName = '',
    String verificationStatus = 'draft',
    bool isActive = true,
  }) async {
    final json = await _remoteDataSource.createProfessionalProfile(
      professionType: professionType,
      professionalNumber: professionalNumber,
      city: city,
      bio: bio,
      interventionZone: interventionZone,
      address: address,
      yearsExperience: yearsExperience,
      languages: languages,
      specialties: specialties,
      officeName: officeName,
      verificationStatus: verificationStatus,
      isActive: isActive,
    );
    return ProfessionalProfileModel.fromJson(json);
  }

  @override
  Future<ProfessionalProfileEntity> updateProfessionalProfile({
    required String id,
    required String professionType,
    String professionalNumber = '',
    required String city,
    required String bio,
    String interventionZone = '',
    String address = '',
    int yearsExperience = 0,
    List<String> languages = const [],
    List<String> specialties = const [],
    String officeName = '',
    String verificationStatus = 'draft',
    bool isActive = true,
  }) async {
    final json = await _remoteDataSource.updateProfessionalProfile(
      id: id,
      professionType: professionType,
      professionalNumber: professionalNumber,
      city: city,
      bio: bio,
      interventionZone: interventionZone,
      address: address,
      yearsExperience: yearsExperience,
      languages: languages,
      specialties: specialties,
      officeName: officeName,
      verificationStatus: verificationStatus,
      isActive: isActive,
    );
    return ProfessionalProfileModel.fromJson(json);
  }

  @override
  Future<Map<String, dynamic>> submitVerification({
    required String professionalId,
    required String professionalNumber,
    PlatformFile? cniFrontFile,
    PlatformFile? cniBackFile,
    PlatformFile? diplomaFile,
    PlatformFile? fullBodyPhotoFile,
    PlatformFile? portraitPhotoFile,
    List<PlatformFile> additionalFiles = const [],
  }) async {
    return _remoteDataSource.submitVerification(
      professionalId: professionalId,
      professionalNumber: professionalNumber,
      cniFrontFile: cniFrontFile,
      cniBackFile: cniBackFile,
      diplomaFile: diplomaFile,
      fullBodyPhotoFile: fullBodyPhotoFile,
      portraitPhotoFile: portraitPhotoFile,
      additionalFiles: additionalFiles,
    );
  }

  @override
  Future<List<ProfessionalProfileEntity>> listFavoriteProfessionals() async {
    final items = await _remoteDataSource.listFavoriteProfessionals();
    return items
        .map((item) {
          final map = item as Map<String, dynamic>;
          final professional = map['professional'] as Map<String, dynamic>? ?? map;
          return ProfessionalProfileModel.fromJson(professional);
        })
        .toList();
  }

  @override
  Future<bool> setFavoriteProfessional({
    required String professionalId,
    required bool isFavorite,
  }) {
    return _remoteDataSource.setFavoriteProfessional(
      professionalId: professionalId,
      isFavorite: isFavorite,
    );
  }
}
