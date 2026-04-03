import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ProfessionalsRemoteDataSource {
  const ProfessionalsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> listProfessionals() async {
    try {
      final response = await _dio.get('/professionals');
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }
      return data as List<dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/professionals/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<List<dynamic>> listFavoriteProfessionals() async {
    try {
      final response = await _dio.get('/professionals/favorites');
      final data = response.data;
      if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }
      return data as List<dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/professionals/favorites/');
    final data = fallback.data;
    if (data is Map<String, dynamic> && data['results'] is List<dynamic>) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProfessional(String id) async {
    try {
      final response = await _dio.get('/professionals/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio.get('/professionals/$id/');
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getMyProfessionalProfile() async {
    try {
      final response = await _dio
          .get('/professionals/me')
          .timeout(const Duration(seconds: 12));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 301 || statusCode == 307) {
        final fallback = await _dio
            .get('/professionals/me/')
            .timeout(const Duration(seconds: 12));
        return fallback.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProfessionalProfile({
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
    final payload = {
      'profession_type': professionType,
      'professional_number': professionalNumber,
      'city': city,
      'bio': bio,
      'intervention_zone': interventionZone,
      'address': address,
      'years_experience': yearsExperience,
      'languages': languages,
      'specialties': specialties,
      'office_name': officeName,
      'verification_status': verificationStatus,
      'is_active': isActive,
    };

    try {
      final response = await _dio
          .post(
            '/professionals',
            data: payload,
          )
          .timeout(const Duration(seconds: 25));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .post(
          '/professionals/',
          data: payload,
        )
        .timeout(const Duration(seconds: 25));
    return fallback.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfessionalProfile({
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
    final payload = {
      'profession_type': professionType,
      'professional_number': professionalNumber,
      'city': city,
      'bio': bio,
      'intervention_zone': interventionZone,
      'address': address,
      'years_experience': yearsExperience,
      'languages': languages,
      'specialties': specialties,
      'office_name': officeName,
      'verification_status': verificationStatus,
      'is_active': isActive,
    };

    try {
      final response = await _dio
          .patch(
            '/professionals/$id',
            data: payload,
          )
          .timeout(const Duration(seconds: 25));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .patch(
          '/professionals/$id/',
          data: payload,
        )
        .timeout(const Duration(seconds: 25));
    return fallback.data as Map<String, dynamic>;
  }

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
    final formDataMap = <String, dynamic>{
      'bar_number': professionalNumber,
    };

    if (cniFrontFile != null) {
      formDataMap['cni_front_file'] = await _multipartFromPlatformFile(cniFrontFile);
    }
    if (cniBackFile != null) {
      formDataMap['cni_back_file'] = await _multipartFromPlatformFile(cniBackFile);
    }
    if (diplomaFile != null) {
      formDataMap['diploma_file'] = await _multipartFromPlatformFile(diplomaFile);
    }
    if (fullBodyPhotoFile != null) {
      formDataMap['full_body_photo_file'] =
          await _multipartFromPlatformFile(fullBodyPhotoFile);
    }
    if (portraitPhotoFile != null) {
      formDataMap['portrait_photo_file'] =
          await _multipartFromPlatformFile(portraitPhotoFile);
    }
    if (additionalFiles.isNotEmpty) {
      formDataMap['additional_doc_files'] = await Future.wait(
        additionalFiles.map(_multipartFromPlatformFile),
      );
    }

    try {
      final response = await _dio
          .post(
            '/professionals/$professionalId/verification',
            data: FormData.fromMap(formDataMap),
            options: Options(contentType: 'multipart/form-data'),
          )
          .timeout(const Duration(seconds: 40));
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }

    final fallback = await _dio
        .post(
          '/professionals/$professionalId/verification/',
          data: FormData.fromMap(formDataMap),
          options: Options(contentType: 'multipart/form-data'),
        )
        .timeout(const Duration(seconds: 40));
    return fallback.data as Map<String, dynamic>;
  }

  Future<MultipartFile> _multipartFromPlatformFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }
    throw ArgumentError('Le fichier selectionne est invalide.');
  }

  Future<bool> setFavoriteProfessional({
    required String professionalId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      try {
        final response = await _dio.post(
          '/professionals/$professionalId/favorite',
        );
        return (response.data['is_favorited'] ?? true) == true;
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
          rethrow;
        }
      }
      final fallback = await _dio.post(
        '/professionals/$professionalId/favorite/',
      );
      return (fallback.data['is_favorited'] ?? true) == true;
    }
    try {
      final response = await _dio.delete(
        '/professionals/$professionalId/favorite',
      );
      return (response.data['is_favorited'] ?? false) == true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 404 && statusCode != 301 && statusCode != 307) {
        rethrow;
      }
    }
    final fallback = await _dio.delete(
      '/professionals/$professionalId/favorite/',
    );
    return (fallback.data['is_favorited'] ?? false) == true;
  }
}
