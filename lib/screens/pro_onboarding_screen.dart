import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/repository_providers.dart';
import '../features/auth/presentation/providers/auth_session_provider.dart';
import '../features/booking/domain/entities/availability_slot_entity.dart';
import '../features/professionals/domain/entities/professional_profile_entity.dart';
import '../models.dart';
import '../theme.dart';

enum _OfferPricingMode { free, paid, dossierReview }

class ProOnboardingScreen extends ConsumerStatefulWidget {
  const ProOnboardingScreen({
    super.key,
    required this.onPublishOffer,
    this.onProfileUpdated,
  });

  final Future<String?> Function(ServiceOffer offer) onPublishOffer;
  final Future<void> Function()? onProfileUpdated;

  @override
  ConsumerState<ProOnboardingScreen> createState() => _ProOnboardingScreenState();
}

class _ProOnboardingScreenState extends ConsumerState<ProOnboardingScreen> {
  LegalProfession _profession = LegalProfession.avocat;
  VerificationStatus _status = VerificationStatus.draft;
  ServiceMode _serviceMode = ServiceMode.both;
  _OfferPricingMode _pricingMode = _OfferPricingMode.dossierReview;
  String? _profileId;
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  bool _publishing = false;
  bool _loadingAvailability = true;
  final List<AvailabilitySlot> _availabilitySlots = <AvailabilitySlot>[];

  PlatformFile? _avatar;
  PlatformFile? _cniFront;
  PlatformFile? _diploma;
  PlatformFile? _portrait;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  final _office = TextEditingController();
  final _number = TextEditingController();
  final _bio = TextEditingController();
  final _address = TextEditingController();
  final _zone = TextEditingController();
  final _languages = TextEditingController(text: 'Francais, Anglais');
  final _specialties = TextEditingController();
  final _experience = TextEditingController(text: '3');
  final _offerTitle = TextEditingController();
  final _offerDescription = TextEditingController();
  final _category = TextEditingController();
  final _fee = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _clientDocs = TextEditingController();
  final _delay = TextEditingController(text: 'Sous 24h');

  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _city = TextEditingController(text: user?.city ?? '');
    _applyPreset(force: true);
    _loadProfile();
    _loadAvailabilitySlots();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _office.dispose();
    _number.dispose();
    _bio.dispose();
    _address.dispose();
    _zone.dispose();
    _languages.dispose();
    _specialties.dispose();
    _experience.dispose();
    _offerTitle.dispose();
    _offerDescription.dispose();
    _category.dispose();
    _fee.dispose();
    _duration.dispose();
    _clientDocs.dispose();
    _delay.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final mine = await ref
          .read(professionalsRepositoryProvider)
          .getMyProfessionalProfile();
      if (mine != null && mounted) {
        _profileId = mine.id;
        _profession = _professionFromApi(mine.professionType);
        _status = _statusFromApi(mine.verificationStatus);
        _name.text = mine.fullName;
        _phone.text = mine.phone;
        _city.text = mine.city;
        _zone.text = mine.interventionZone;
        _office.text = mine.officeName;
        _number.text = mine.professionalNumber;
        _bio.text = mine.bio;
        _address.text = mine.address;
        _languages.text = mine.languages.join(', ');
        _specialties.text = mine.specialties.join(', ');
        _experience.text = mine.yearsExperience.toString();
      }
    } catch (_) {
      // Keep editable form if load fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailabilitySlots() async {
    try {
      final slots =
          await ref.read(bookingRepositoryProvider).listAvailabilitySlots();
      if (!mounted) {
        return;
      }
      setState(() {
        _availabilitySlots
          ..clear()
          ..addAll(slots.map(_availabilityFromEntity));
        _availabilitySlots.sort((a, b) {
          final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
          if (dayCompare != 0) {
            return dayCompare;
          }
          return a.startTime.compareTo(b.startTime);
        });
        _loadingAvailability = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingAvailability = false);
    }
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      switch (key) {
        case 'avatar':
          _avatar = file;
          break;
        case 'cniFront':
          _cniFront = file;
          break;
        case 'diploma':
          _diploma = file;
          break;
        case 'portrait':
          _portrait = file;
          break;
      }
    });
  }

  Future<void> _saveProfile() async {
    await _persistProfile();
  }

  Future<bool> _persistProfile() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().length < 3 ||
        _phone.text.trim().length < 6 ||
        _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez correctement le nom, le telephone et la ville.'),
        ),
      );
      return false;
    }
    setState(() => _saving = true);
    String? userSyncWarning;
    try {
      try {
        final updatedUser = await ref.read(authRepositoryProvider).updateMe(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              city: _city.text.trim(),
              avatarFile: _avatar,
            );
        ref.read(authSessionProvider.notifier).updateUser(updatedUser);
      } on DioException catch (error) {
        userSyncWarning = _apiErrorMessage(
          error,
          fallback: 'Les informations du compte n ont pas ete entierement synchronisees.',
        );
      } catch (_) {
        userSyncWarning =
            'Les informations du compte n ont pas ete entierement synchronisees.';
      }

      final profile = await _upsertProfessionalProfile();
      _profileId = profile.id;
      _status = _statusFromApi(profile.verificationStatus);
      try {
        final freshUser = await ref.read(authRepositoryProvider).me();
        ref.read(authSessionProvider.notifier).updateUser(freshUser);
      } catch (_) {
        // Keep the local session if the profile save succeeded but the user refresh failed.
      }
      _triggerBackgroundRefresh();
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userSyncWarning == null
                ? 'Profil professionnel enregistre.'
                : 'Profil professionnel enregistre. $userSyncWarning',
          ),
        ),
      );
      return true;
    } on DioException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _apiErrorMessage(
              error,
              fallback: 'Echec de sauvegarde du profil.',
            ),
          ),
        ),
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de sauvegarde du profil.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return false;
  }

  Future<void> _submitVerification() async {
    if (_profileId == null) {
      final saved = await _persistProfile();
      if (!saved) {
        return;
      }
      if (_profileId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrez d abord le profil.')),
        );
        return;
      }
    }
    if (_cniFront == null ||
        _diploma == null ||
        _portrait == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoutez la piece d identite ou carte professionnelle, le diplome ou attestation et le selfie.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final professionalsRepository = ref.read(professionalsRepositoryProvider);
      Future<Map<String, dynamic>> submitFor(String professionalId) {
        return professionalsRepository.submitVerification(
          professionalId: professionalId,
          professionalNumber: _number.text.trim(),
          cniFrontFile: _cniFront,
          diplomaFile: _diploma,
          portraitPhotoFile: _portrait,
        );
      }

      Map<String, dynamic> result;
      try {
        result = await submitFor(_profileId!);
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) {
          rethrow;
        }
        final restoredProfile =
            await professionalsRepository.getMyProfessionalProfile();
        if (restoredProfile == null) {
          rethrow;
        }
        _profileId = restoredProfile.id;
        result = await submitFor(restoredProfile.id);
      }
      if (!mounted) return;
      setState(() => _status = _statusFromApi((result['status'] ?? '').toString()));
      _triggerBackgroundRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification soumise avec succes.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _apiErrorMessage(
              error,
              fallback: 'Echec de l envoi des documents.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec de l envoi des documents.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _triggerBackgroundRefresh() {
    final onProfileUpdated = widget.onProfileUpdated;
    if (onProfileUpdated == null) {
      return;
    }

    Future<void>(() async {
      try {
        await onProfileUpdated().timeout(const Duration(seconds: 4));
      } catch (_) {
        // Do not block the UI when the shell refresh is slow.
      }
    });
  }

  Future<void> _publish() async {
    if (_offerTitle.text.trim().isEmpty ||
        _offerDescription.text.trim().isEmpty ||
        _category.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez le titre, la description et la categorie.'),
        ),
      );
      return;
    }
    final amount = int.tryParse(_fee.text.trim()) ?? 0;
    if (_pricingMode == _OfferPricingMode.paid && amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez des honoraires valides pour une consultation payante.'),
        ),
      );
      return;
    }
    setState(() => _publishing = true);
    final computedPriceType = switch (_pricingMode) {
      _OfferPricingMode.free => 'fixed',
      _OfferPricingMode.paid => 'fixed',
      _OfferPricingMode.dossierReview => 'negotiable',
    };
    final computedAmount = switch (_pricingMode) {
      _OfferPricingMode.free => 0,
      _OfferPricingMode.paid => amount,
      _OfferPricingMode.dossierReview => 0,
    };
    try {
      final profile = await _upsertProfessionalProfile();
      final servicesRepository = ref.read(servicesRepositoryProvider);
      final createdService = await servicesRepository.createService(
        title: _offerTitle.text.trim(),
        description: _offerDescription.text.trim(),
        mode: _serviceModeApi(_serviceMode),
        priceType: computedPriceType,
        amount: computedAmount.toDouble(),
        durationMinutes: int.tryParse(_duration.text.trim()) ?? 30,
        city: _city.text.trim(),
        address: _address.text.trim(),
        currency: 'XAF',
        isPublished: profile.verificationStatus == 'verified',
        categoryInput: _category.text.trim(),
      );

      _profileId = profile.id;
      _status = _statusFromApi(profile.verificationStatus);
      _offerTitle.clear();
      _offerDescription.clear();
      _category.clear();
      _fee.clear();
      _clientDocs.clear();
      _delay.text = 'Sous 24h';
      _duration.text = '30';
      setState(() => _pricingMode = _OfferPricingMode.dossierReview);
      _triggerBackgroundRefresh();
      if (!mounted) {
        return;
      }
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdService.isPublished
                ? 'Offre publiee avec succes.'
                : 'Offre enregistree en brouillon. Elle sera visible apres verification.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _apiErrorMessage(
              error,
              fallback: 'Publication impossible.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication impossible.')),
      );
    }
  }

  Future<void> _openAvailabilityEditor([AvailabilitySlot? slot]) async {
    if (_profileId == null) {
      await _saveProfile();
      if (_profileId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enregistrez d abord votre profil avant d ajouter des disponibilites.',
            ),
          ),
        );
        return;
      }
    }

    final day = ValueNotifier<int>(slot?.dayOfWeek ?? 1);
    final startController = TextEditingController(
      text: _formatTimeInput(slot?.startTime ?? '08:00:00'),
    );
    final endController = TextEditingController(
      text: _formatTimeInput(slot?.endTime ?? '08:30:00'),
    );
    final durationController = TextEditingController(
      text: (slot?.slotDuration ?? 30).toString(),
    );
    final enabled = ValueNotifier<bool>(slot?.isAvailable ?? true);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(slot == null ? 'Ajouter un creneau' : 'Modifier le creneau'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: day,
                  builder: (context, selectedDay, _) {
                    return DropdownButtonFormField<int>(
                      value: selectedDay,
                      items: List.generate(
                        7,
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(_dayLabel(index + 1)),
                        ),
                      ),
                      onChanged: (value) {
                        day.value = value ?? 1;
                      },
                      decoration:
                          const InputDecoration(labelText: 'Jour de disponibilite'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Heure de debut',
                    hintText: '08:00',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: 'Heure de fin',
                    hintText: '08:30',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duree du slot (minutes)',
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: enabled,
                  builder: (context, isEnabled, _) {
                    return SwitchListTile.adaptive(
                      value: isEnabled,
                      onChanged: (value) => enabled.value = value,
                      title: const Text('Disponible a la reservation'),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    final selectedDay = day.value;
    final selectedEnabled = enabled.value;
    day.dispose();
    enabled.dispose();

    if (shouldSave != true || !mounted) {
      startController.dispose();
      endController.dispose();
      durationController.dispose();
      return;
    }

    final startTime = _normalizeTimeInput(startController.text);
    final endTime = _normalizeTimeInput(endController.text);
    final duration = int.tryParse(durationController.text.trim()) ?? 30;

    startController.dispose();
    endController.dispose();
    durationController.dispose();

    if (startTime == null || endTime == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez des horaires valides au format HH:MM.'),
        ),
      );
      return;
    }

    try {
      final profile = await _upsertProfessionalProfile();
      _profileId = profile.id;
      _status = _statusFromApi(profile.verificationStatus);

      if (slot == null) {
        await ref.read(bookingRepositoryProvider).createAvailabilitySlot(
              dayOfWeek: selectedDay,
              startTime: startTime,
              endTime: endTime,
              slotDuration: duration,
              isAvailable: selectedEnabled,
            );
      } else {
        await ref.read(bookingRepositoryProvider).updateAvailabilitySlot(
              slotId: slot.id,
              dayOfWeek: selectedDay,
              startTime: startTime,
              endTime: endTime,
              slotDuration: duration,
              isAvailable: selectedEnabled,
            );
      }
      await _loadAvailabilitySlots();
      _triggerBackgroundRefresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            slot == null
                ? 'Disponibilite ajoutee.'
                : 'Disponibilite mise a jour.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? payload.entries.map((entry) => '${entry.key}: ${entry.value}').join(' | ')
          : (error.message ?? 'Echec lors de l enregistrement du creneau.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec lors de l enregistrement du creneau.')),
      );
    }
  }

  Future<ProfessionalProfileEntity> _upsertProfessionalProfile() async {
    final professionalsRepository = ref.read(professionalsRepositoryProvider);
    final years = int.tryParse(_experience.text.trim()) ?? 0;
    final professionType = _profession.name;
    final professionalNumber = _number.text.trim();
    final city = _city.text.trim();
    final bio = _bio.text.trim();
    final interventionZone = _zone.text.trim();
    final address = _address.text.trim();
    final languages = _split(_languages.text);
    final specialties = _split(_specialties.text);
    final officeName = _office.text.trim();
    final verificationStatus = _statusApi(_status);

    Future<ProfessionalProfileEntity> createProfile() {
      return professionalsRepository.createProfessionalProfile(
        professionType: professionType,
        professionalNumber: professionalNumber,
        city: city,
        bio: bio,
        interventionZone: interventionZone,
        address: address,
        yearsExperience: years,
        languages: languages,
        specialties: specialties,
        officeName: officeName,
        verificationStatus: verificationStatus,
        isActive: true,
      );
    }

    Future<ProfessionalProfileEntity> updateProfile(String id) {
      return professionalsRepository.updateProfessionalProfile(
        id: id,
        professionType: professionType,
        professionalNumber: professionalNumber,
        city: city,
        bio: bio,
        interventionZone: interventionZone,
        address: address,
        yearsExperience: years,
        languages: languages,
        specialties: specialties,
        officeName: officeName,
        verificationStatus: verificationStatus,
        isActive: true,
      );
    }

    if (_profileId != null && _profileId!.isNotEmpty) {
      try {
        return await updateProfile(_profileId!);
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode != 404) {
          rethrow;
        }
      }
    }

    final existingProfile = await professionalsRepository.getMyProfessionalProfile();
    if (existingProfile != null) {
      _profileId = existingProfile.id;
      return updateProfile(existingProfile.id);
    }

    try {
      return await createProfile();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode != 400 && statusCode != 409) {
        rethrow;
      }
      final restoredProfile =
          await professionalsRepository.getMyProfessionalProfile();
      if (restoredProfile != null) {
        _profileId = restoredProfile.id;
        return updateProfile(restoredProfile.id);
      }
      rethrow;
    }
  }

  String _apiErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return payload.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');
    }
    if (payload is List) {
      return payload.join(' | ');
    }
    return error.message ?? fallback;
  }

  Future<void> _deleteAvailabilitySlot(AvailabilitySlot slot) async {
    try {
      await ref.read(bookingRepositoryProvider).deleteAvailabilitySlot(slot.id);
      await _loadAvailabilitySlots();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilite supprimee.')),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? payload.entries.map((entry) => '${entry.key}: ${entry.value}').join(' | ')
          : (error.message ?? 'Suppression impossible.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression impossible.')),
      );
    }
  }

  void _applyPreset({bool force = false}) {
    if (force || _office.text.isEmpty) _office.text = _officeLabel;
    if (force || _category.text.isEmpty) _category.text = _defaultCategory;
    if (force || _specialties.text.isEmpty) _specialties.text = _defaultSpecialties;
  }

  String get _officeLabel => switch (_profession) {
        LegalProfession.avocat => 'Cabinet d avocat',
        LegalProfession.huissier => 'Etude d huissier',
        LegalProfession.notaire => 'Etude notariale',
      };

  String get _numberLabel => switch (_profession) {
        LegalProfession.avocat => 'Numero du barreau',
        LegalProfession.huissier => 'Numero professionnel d huissier',
        LegalProfession.notaire => 'Numero de charge notariale',
      };

  String get _specialtiesLabel => switch (_profession) {
        LegalProfession.avocat => 'Specialites juridiques',
        LegalProfession.huissier => 'Types d interventions',
        LegalProfession.notaire => 'Types d actes traites',
      };

  String get _defaultCategory => switch (_profession) {
        LegalProfession.avocat => 'Consultation',
        LegalProfession.huissier => 'Signification',
        LegalProfession.notaire => 'Acte notarie',
      };

  String get _defaultSpecialties => switch (_profession) {
        LegalProfession.avocat => 'Droit penal, Droit foncier',
        LegalProfession.huissier => 'Constat, Recouvrement',
        LegalProfession.notaire => 'Contrats, Successions',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final user = ref.watch(authSessionProvider).user;
    ImageProvider<Object>? avatarProvider;
    if (_avatar?.bytes != null) {
      avatarProvider = MemoryImage(_avatar!.bytes!);
    } else if (user?.avatar.isNotEmpty ?? false) {
      avatarProvider = NetworkImage(user!.avatar);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE7F3FB),
            colors.mist,
            const Color(0xFFF5F9FC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [colors.navy, colors.navySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.navy.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration professionnelle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completez votre identite, vos justificatifs, vos disponibilites et vos offres.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD9E4F3),
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        backgroundImage: avatarProvider,
                        child: (_avatar == null && (user?.avatar.isEmpty ?? true))
                            ? Text(
                                _initials(_name.text),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.text.trim().isEmpty ? 'Professionnel' : _name.text.trim(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Statut: ${_status.label}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              title: 'Compte professionnel',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickFile('avatar'),
                    icon: const Icon(Icons.photo_camera_back_rounded),
                    label: Text(_avatar?.name ?? 'Changer la photo de profil'),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(_status, colors).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Statut: ${_status.label}',
                      style: TextStyle(
                        color: _statusColor(_status, colors),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              title: 'Identite professionnelle',
              child: Column(
                children: [
                SegmentedButton<LegalProfession>(
                  segments: const [
                    ButtonSegment(value: LegalProfession.avocat, label: Text('Avocat')),
                    ButtonSegment(value: LegalProfession.huissier, label: Text('Huissier')),
                    ButtonSegment(value: LegalProfession.notaire, label: Text('Notaire')),
                  ],
                  selected: {_profession},
                  onSelectionChanged: (values) {
                    setState(() {
                      _profession = values.first;
                      _applyPreset(force: true);
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
                const SizedBox(height: 12),
                TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Telephone')),
                const SizedBox(height: 12),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'Ville')),
                const SizedBox(height: 12),
                TextField(controller: _office, decoration: InputDecoration(labelText: _officeLabel)),
                const SizedBox(height: 12),
                TextField(controller: _number, decoration: InputDecoration(labelText: _numberLabel)),
                const SizedBox(height: 12),
                TextField(controller: _specialties, decoration: InputDecoration(labelText: _specialtiesLabel)),
                const SizedBox(height: 12),
                TextField(controller: _zone, decoration: const InputDecoration(labelText: 'Zone d intervention')),
                const SizedBox(height: 12),
                TextField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse')),
                const SizedBox(height: 12),
                TextField(controller: _experience, decoration: const InputDecoration(labelText: 'Annees d experience')),
                const SizedBox(height: 12),
                TextField(controller: _languages, decoration: const InputDecoration(labelText: 'Langues parlees')),
                const SizedBox(height: 12),
                TextField(controller: _bio, maxLines: 4, decoration: const InputDecoration(labelText: 'Biographie')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer le profil'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Verification du compte',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seulement 3 pieces sont demandees pour verifier le compte professionnel.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.camrlex.body,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Formats acceptes: PNG, JPG, JPEG ou PDF.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.camrlex.body,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _uploadTile(
                  context,
                  'CNI ou carte professionnelle',
                  _cniFront,
                  () => _pickFile('cniFront'),
                ),
                _uploadTile(
                  context,
                  'Diplome ou attestation',
                  _diploma,
                  () => _pickFile('diploma'),
                ),
                _uploadTile(
                  context,
                  'Selfie',
                  _portrait,
                  () => _pickFile('portrait'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submitVerification,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_user_rounded),
                  label: Text(_submitting ? 'Envoi des pieces...' : 'Soumettre les documents'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Disponibilites',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurez les jours et horaires visibles pour les prochaines reservations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.camrlex.body,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 14),
                if (_loadingAvailability)
                  const Center(child: CircularProgressIndicator())
                else if (_availabilitySlots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.camrlex.mist,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Aucun creneau configure pour le moment.',
                    ),
                  )
                else
                  ..._availabilitySlots.map(
                    (slot) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.camrlex.mist,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dayLabel(slot.dayOfWeek),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTimeInput(slot.startTime)} - ${_formatTimeInput(slot.endTime)} - ${slot.slotDuration} min',
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: slot.isAvailable,
                            onChanged: (_) {
                              _openAvailabilityEditor(slot);
                            },
                          ),
                          IconButton(
                            onPressed: () => _openAvailabilityEditor(slot),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _deleteAvailabilitySlot(slot),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _openAvailabilityEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter un creneau'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            title: 'Publier une offre',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _offerTitle, decoration: const InputDecoration(labelText: 'Titre du service')),
                const SizedBox(height: 12),
                TextField(controller: _offerDescription, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: _category, decoration: const InputDecoration(labelText: 'Categorie')),
                const SizedBox(height: 12),
                Text(
                  'Type de consultation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<_OfferPricingMode>(
                  segments: const [
                    ButtonSegment<_OfferPricingMode>(
                      value: _OfferPricingMode.free,
                      label: Text('Gratuite'),
                      icon: Icon(Icons.volunteer_activism_rounded),
                    ),
                    ButtonSegment<_OfferPricingMode>(
                      value: _OfferPricingMode.paid,
                      label: Text('Payante'),
                      icon: Icon(Icons.payments_rounded),
                    ),
                    ButtonSegment<_OfferPricingMode>(
                      value: _OfferPricingMode.dossierReview,
                      label: Text('Selon dossier'),
                      icon: Icon(Icons.description_outlined),
                    ),
                  ],
                  selected: {_pricingMode},
                  onSelectionChanged: (values) {
                    setState(() {
                      _pricingMode = values.first;
                      if (_pricingMode != _OfferPricingMode.paid) {
                        _fee.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  switch (_pricingMode) {
                    _OfferPricingMode.free =>
                      'La consultation apparaitra comme gratuite sur le feed.',
                    _OfferPricingMode.paid =>
                      'Le montant sera visible directement pour le client.',
                    _OfferPricingMode.dossierReview =>
                      'Les honoraires seront fixes apres etude du dossier.',
                  },
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.camrlex.body,
                        height: 1.45,
                      ),
                ),
                if (_pricingMode == _OfferPricingMode.paid) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fee,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant de la consultation (FCFA)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(controller: _duration, decoration: const InputDecoration(labelText: 'Duree en minutes')),
                const SizedBox(height: 12),
                TextField(
                  controller: _clientDocs,
                  decoration: const InputDecoration(
                    labelText: 'Documents a demander au client si necessaire',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _delay, decoration: const InputDecoration(labelText: 'Delai d execution')),
                const SizedBox(height: 12),
                DropdownButtonFormField<ServiceMode>(
                  value: _serviceMode,
                  items: ServiceMode.values.map((mode) => DropdownMenuItem(value: mode, child: Text(mode.label))).toList(),
                  onChanged: (value) => setState(() => _serviceMode = value ?? ServiceMode.both),
                  decoration: const InputDecoration(labelText: 'Mode du service'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.campaign_rounded),
                  label: Text(_publishing ? 'Publication...' : 'Publier l offre'),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.camrlex.line),
        boxShadow: [
          BoxShadow(
            color: context.camrlex.navy.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _uploadTile(BuildContext context, String label, PlatformFile? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.camrlex.line),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_file_rounded, color: context.camrlex.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file?.name ?? label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                file == null ? 'Choisir' : 'Remplacer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.camrlex.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  String _initials(String value) => value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  LegalProfession _professionFromApi(String value) => LegalProfession.values.firstWhere(
        (item) => item.name == value,
        orElse: () => LegalProfession.avocat,
      );

  VerificationStatus _statusFromApi(String value) {
    switch (value) {
      case 'submitted':
        return VerificationStatus.submitted;
      case 'under_review':
        return VerificationStatus.underReview;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'needs_completion':
        return VerificationStatus.needsCompletion;
      case 'suspended':
        return VerificationStatus.suspended;
      default:
        return VerificationStatus.draft;
    }
  }

  String _statusApi(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.draft:
        return 'draft';
      case VerificationStatus.submitted:
        return 'submitted';
      case VerificationStatus.underReview:
        return 'under_review';
      case VerificationStatus.verified:
        return 'verified';
      case VerificationStatus.rejected:
        return 'rejected';
      case VerificationStatus.needsCompletion:
        return 'needs_completion';
      case VerificationStatus.suspended:
        return 'suspended';
    }
  }

  String _serviceModeApi(ServiceMode mode) {
    switch (mode) {
      case ServiceMode.online:
        return 'online';
      case ServiceMode.inPerson:
        return 'onsite';
      case ServiceMode.both:
        return 'both';
    }
  }

  Color _statusColor(VerificationStatus status, CamrlexColors colors) {
    switch (status) {
      case VerificationStatus.verified:
        return colors.success;
      case VerificationStatus.rejected:
        return const Color(0xFFB3261E);
      case VerificationStatus.submitted:
      case VerificationStatus.underReview:
        return colors.gold;
      case VerificationStatus.needsCompletion:
        return const Color(0xFFB56A00);
      case VerificationStatus.suspended:
        return const Color(0xFF6B7280);
      case VerificationStatus.draft:
        return colors.navySoft;
    }
  }

  AvailabilitySlot _availabilityFromEntity(AvailabilitySlotEntity entity) {
    return AvailabilitySlot(
      id: entity.id,
      professionalId: entity.professionalId,
      dayOfWeek: entity.dayOfWeek,
      startTime: entity.startTime,
      endTime: entity.endTime,
      slotDuration: entity.slotDuration,
      isAvailable: entity.isAvailable,
    );
  }

  String _dayLabel(int day) {
    switch (day) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      default:
        return 'Dimanche';
    }
  }

  String _formatTimeInput(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return '$hour:$minute';
  }

  String? _normalizeTimeInput(String value) {
    final raw = value.trim();
    final parts = raw.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}
