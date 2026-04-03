import 'package:file_picker/file_picker.dart';

import '../entities/professional_profile_entity.dart';

abstract class ProfessionalsRepository {
  Future<List<ProfessionalProfileEntity>> listProfessionals();
  Future<ProfessionalProfileEntity> getProfessional(String id);
  Future<ProfessionalProfileEntity?> getMyProfessionalProfile();
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
  });
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
  });

  Future<Map<String, dynamic>> submitVerification({
    required String professionalId,
    required String professionalNumber,
    PlatformFile? cniFrontFile,
    PlatformFile? cniBackFile,
    PlatformFile? diplomaFile,
    PlatformFile? fullBodyPhotoFile,
    PlatformFile? portraitPhotoFile,
    List<PlatformFile> additionalFiles = const [],
  });

  Future<List<ProfessionalProfileEntity>> listFavoriteProfessionals();
  Future<bool> setFavoriteProfessional({
    required String professionalId,
    required bool isFavorite,
  });
}
