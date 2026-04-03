import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/providers/repository_providers.dart';
import '../core/utils/file_download.dart';
import '../features/auth/presentation/providers/auth_session_provider.dart';
import '../features/booking/domain/entities/booking_entity.dart';
import '../features/professionals/domain/entities/professional_profile_entity.dart';
import '../features/services/domain/entities/service_offer_entity.dart';
import '../models.dart';
import '../theme.dart';
import 'admin_dashboard_screen.dart';
import 'bookings_screen.dart';
import 'feed_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'pro_dashboard_screen.dart';
import 'pro_onboarding_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({
    super.key,
    required this.role,
    this.initialIndex = 0,
  });

  final UserRole role;
  final int initialIndex;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late List<ServiceOffer> _offers;
  late List<BookingRequest> _bookings;
  late List<ConversationPreview> _conversations;
  late List<AppNotification> _notifications;
  final Set<String> _inProgressBookingIds = <String>{};
  final Set<String> _archivedConversationIds = <String>{};
  final Set<String> _deletedConversationIds = <String>{};
  final Set<String> _favoriteProfessionalIds = <String>{};
  ProfessionalProfile? _myProfessionalProfile;
  String? _selectedConversationId;
  late int _currentIndex;
  Timer? _notificationTimer;
  final Set<String> _seenNotificationIds = <String>{};
  bool _isSyncing = false;
  bool _usingRemoteData = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _offers = <ServiceOffer>[];
    _bookings = <BookingRequest>[];
    _conversations = <ConversationPreview>[];
    _notifications = <AppNotification>[];
    _syncRemoteContent();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 18),
      (_) => _syncRemoteContent(showPushFeedback: true),
    );
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex && mounted) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncRemoteContent({
    bool showPushFeedback = false,
  }) async {
    if (!mounted || _isSyncing) {
      return;
    }
    final session = ref.read(authSessionProvider);
    final accessToken = session.accessToken ?? '';
    if (!session.isAuthenticated || accessToken.isEmpty) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _usingRemoteData = false;
        });
      }
      return;
    }
    setState(() => _isSyncing = true);

    try {
      final professionalsRepository = ref.read(professionalsRepositoryProvider);
      final servicesRepository = ref.read(servicesRepositoryProvider);
      final bookingRepository = ref.read(bookingRepositoryProvider);
      List<ProfessionalProfileEntity> favoriteProfessionals =
          const <ProfessionalProfileEntity>[];
      if (widget.role == UserRole.client && accessToken.isNotEmpty) {
        try {
          favoriteProfessionals =
              await professionalsRepository.listFavoriteProfessionals();
        } on DioException {
          favoriteProfessionals = const <ProfessionalProfileEntity>[];
        } catch (_) {
          favoriteProfessionals = const <ProfessionalProfileEntity>[];
        }
      }
      final messagingRemoteDataSource =
          ref.read(messagingRemoteDataSourceProvider);
      final notificationsRemoteDataSource =
          ref.read(notificationsRemoteDataSourceProvider);

      List<ProfessionalProfileEntity> professionals =
          const <ProfessionalProfileEntity>[];
      try {
        professionals = await professionalsRepository.listProfessionals();
      } on DioException {
        professionals = const <ProfessionalProfileEntity>[];
      } catch (_) {
        professionals = const <ProfessionalProfileEntity>[];
      }
      final professionalById = <String, ProfessionalProfileEntity>{
        for (final professional in professionals) professional.id: professional,
      };
      final sessionUserId = ref.read(authSessionProvider).user?.id ?? '';
      ProfessionalProfile? ownProfile = _myProfessionalProfile;
      try {
        final mine = await professionalsRepository.getMyProfessionalProfile();
        if (mine != null) {
          ownProfile = _localProfileFromEntity(mine);
          professionalById[mine.id] = mine;
        }
      } on DioException {
        // Keep the previous local profile if the endpoint is temporarily down.
      } catch (_) {
        // Keep the previous local profile if the endpoint is temporarily down.
      }
      for (final professional in professionals) {
        if (professional.userId == sessionUserId) {
          ownProfile = _localProfileFromEntity(professional);
          break;
        }
      }

      List<ServiceOffer> mappedOffers = _offers;
      try {
        final services = await servicesRepository.listServices();
        mappedOffers = services
            .map((service) => _offerFromRemote(service, professionalById))
            .toList();
      } on DioException {
        mappedOffers = _offers;
      } catch (_) {
        mappedOffers = _offers;
      }

      List<BookingRequest> mappedBookings = <BookingRequest>[];
      List<ConversationPreview> mappedConversations = <ConversationPreview>[];
      Set<String> archivedConversationIds = <String>{};
      List<AppNotification> mappedNotifications = <AppNotification>[];
      try {
        final bookings = await bookingRepository.listBookings();
        mappedBookings = bookings
            .map((booking) => _bookingFromRemote(booking, mappedOffers))
            .toList()
          ..sort(_compareBookings);
      } on DioException {
        mappedBookings = _bookings;
      } catch (_) {
        mappedBookings = _bookings;
      }

      try {
        final conversations =
            await messagingRemoteDataSource.listConversations();
        archivedConversationIds = conversations
            .whereType<Map<String, dynamic>>()
            .where((item) => item['is_archived'] == true)
            .map((item) => (item['id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();
        mappedConversations = conversations
            .map(
              (item) => _conversationFromRemote(item as Map<String, dynamic>),
            )
            .toList()
          ..sort(_compareConversations);
      } on DioException {
        mappedConversations = _conversations;
      } catch (_) {
        mappedConversations = _conversations;
      }

      try {
        final notifications =
            await notificationsRemoteDataSource.listNotifications();
        mappedNotifications = notifications
            .map(
              (item) => _notificationFromRemote(item as Map<String, dynamic>),
            )
            .toList();
      } on DioException {
        mappedNotifications = _notifications;
      } catch (_) {
        mappedNotifications = _notifications;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _offers = mappedOffers;
        _bookings = mappedBookings;
        _conversations = mappedConversations;
        _notifications = mappedNotifications;
        _archivedConversationIds
          ..clear()
          ..addAll(archivedConversationIds);
        _deletedConversationIds.removeWhere(
          (id) => mappedConversations.any((item) => item.id == id),
        );
        _myProfessionalProfile = ownProfile;
        _favoriteProfessionalIds
          ..clear()
          ..addAll(favoriteProfessionals.map((item) => item.id));
        _usingRemoteData = true;
        _isSyncing = false;
      });

      _handleIncomingNotifications(
        mappedNotifications,
        showPushFeedback: showPushFeedback,
      );
    } on DioException {
      if (!mounted) {
        return;
      }
      setState(() => _isSyncing = false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSyncing = false);
    }
  }

  void _handleIncomingNotifications(
    List<AppNotification> notifications, {
    required bool showPushFeedback,
  }) {
    final unread = notifications.where((item) => item.isUnread).toList();
    final newUnread = unread
        .where((item) => !_seenNotificationIds.contains(item.id))
        .toList();

    for (final item in unread) {
      _seenNotificationIds.add(item.id);
    }

    if (!showPushFeedback || !mounted || newUnread.isEmpty) {
      return;
    }

    final latest = newUnread.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${latest.title} - ${latest.body}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _addOffer(ServiceOffer offer) async {
    try {
      final servicesRepository = ref.read(servicesRepositoryProvider);
      final ensuredProfile =
          await _upsertRemoteProfessionalProfileFromOffer(offer);
      final createdService = await servicesRepository.createService(
        title: offer.title,
        description: offer.description,
        mode: _serviceModeApi(offer.mode),
        priceType: offer.priceType,
        amount: offer.feeCfa.toDouble(),
        durationMinutes: _parseDurationMinutes(offer.durationLabel),
        city: offer.city,
        address: offer.profile.address,
        currency: 'XAF',
        isPublished: offer.isPublished,
        categoryInput: offer.category,
      );
      if (mounted) {
        try {
          final freshUser = await ref.read(authRepositoryProvider).me();
          ref.read(authSessionProvider.notifier).updateUser(freshUser);
        } catch (_) {
          // Keep the current session if refreshing the user fails.
        }
        final localOffer = _offerFromRemote(
          createdService,
          {ensuredProfile.id: ensuredProfile},
        );
        setState(() {
          _myProfessionalProfile = _localProfileFromEntity(ensuredProfile);
          _offers = [
            localOffer,
            ..._offers.where((item) => item.id != localOffer.id),
          ];
        });
        unawaited(_syncRemoteContent());
      }
      return null;
    } on DioException catch (error) {
      return _apiErrorMessage(error.response?.data, error.message);
    } catch (_) {
      return 'Publication impossible.';
    }
  }

  Future<ProfessionalProfileEntity> _upsertRemoteProfessionalProfileFromOffer(
    ServiceOffer offer,
  ) async {
    final professionalsRepository = ref.read(professionalsRepositoryProvider);
    final verificationStatus = _verificationStatusApi(
      offer.profile.verificationStatus,
    );

    Future<ProfessionalProfileEntity> createProfile() {
      return professionalsRepository.createProfessionalProfile(
        professionType: offer.profile.profession.name,
        professionalNumber: offer.profile.professionalNumber,
        city: offer.profile.city,
        bio: offer.profile.bio,
        interventionZone: offer.profile.interventionZone,
        address: offer.profile.address,
        yearsExperience: offer.profile.yearsExperience,
        languages: offer.profile.languages,
        specialties: offer.profile.specialties,
        officeName: offer.profile.officeName,
        verificationStatus: verificationStatus,
        isActive: true,
      );
    }

    Future<ProfessionalProfileEntity> updateProfile(String id) {
      return professionalsRepository.updateProfessionalProfile(
        id: id,
        professionType: offer.profile.profession.name,
        professionalNumber: offer.profile.professionalNumber,
        city: offer.profile.city,
        bio: offer.profile.bio,
        interventionZone: offer.profile.interventionZone,
        address: offer.profile.address,
        yearsExperience: offer.profile.yearsExperience,
        languages: offer.profile.languages,
        specialties: offer.profile.specialties,
        officeName: offer.profile.officeName,
        verificationStatus: verificationStatus,
        isActive: true,
      );
    }

    final existingProfile = await professionalsRepository.getMyProfessionalProfile();
    if (existingProfile != null) {
      try {
        return await updateProfile(existingProfile.id);
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) {
          rethrow;
        }
      }
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
        return updateProfile(restoredProfile.id);
      }
      rethrow;
    }
  }

  String _apiErrorMessage(Object? payload, String? fallback) {
    if (payload is Map<String, dynamic>) {
      return payload.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');
    }
    if (payload is List) {
      return payload.join(' | ');
    }
    return fallback ?? 'Operation impossible.';
  }

  Future<String?> _addBooking(
    ServiceOffer offer,
    ServiceMode mode,
    BookingUrgency urgency,
    String issueTitle,
    String issueSummary,
    String appointmentDate,
    String startTime,
    String endTime,
  ) async {
    try {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final createdBooking = await bookingRepository.createBooking(
        serviceId: offer.id,
        bookingType: mode == ServiceMode.online ? 'online' : 'onsite',
        appointmentDate: appointmentDate,
        startTime: startTime,
        endTime: endTime,
        issueTitle: issueTitle,
        issueSummary: issueSummary,
        urgency: urgency.apiValue,
        note: issueSummary,
      );

      if (mounted) {
        final remoteBooking = _bookingFromRemote(
          createdBooking,
          [offer, ..._offers],
        );
        setState(() {
          _bookings = [
            remoteBooking,
            ..._bookings.where((item) => item.id != remoteBooking.id),
          ]..sort(_compareBookings);
        });
        unawaited(_syncRemoteContent());
      }
      return null;
    } on DioException catch (error) {
      return _apiErrorMessage(error.response?.data, error.message);
    } catch (_) {
      return 'Creation de la reservation impossible.';
    }
  }

  Future<String?> _respondToBooking(
    BookingRequest booking,
    bool accept,
  ) async {
    final previous = booking.status;
    final nextStatus = accept ? BookingStatus.accepted : BookingStatus.refused;
    if (mounted) {
      setState(() {
        _bookings = _bookings
            .map(
              (item) => item.id == booking.id
                  ? BookingRequest(
                      id: item.id,
                      clientName: item.clientName,
                      serviceTitle: item.serviceTitle,
                      professionalName: item.professionalName,
                      mode: item.mode,
                      dateLabel: item.dateLabel,
                      priceCfa: item.priceCfa,
                      status: nextStatus,
                      paymentStatus: item.paymentStatus,
                      locationLabel: item.locationLabel,
                      urgency: item.urgency,
                      createdAt: item.createdAt,
                      issueTitle: item.issueTitle,
                      issueSummary: item.issueSummary,
                      conversationId: item.conversationId,
                      paymentId: item.paymentId,
                      issueReportStatus: item.issueReportStatus,
                      hasReview: item.hasReview,
                    )
                  : item,
            )
            .toList()
          ..sort(_compareBookings);
      });
    }

    try {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      await bookingRepository.updateBookingStatus(
        bookingId: booking.id,
        action: accept ? 'accept' : 'reject',
      );
      if (mounted) {
        await _syncRemoteContent();
      }
      return accept ? 'Reservation acceptee.' : 'Reservation refusee.';
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          _bookings = _bookings
              .map(
                (item) => item.id == booking.id
                    ? BookingRequest(
                        id: item.id,
                        clientName: item.clientName,
                        serviceTitle: item.serviceTitle,
                        professionalName: item.professionalName,
                        mode: item.mode,
                        dateLabel: item.dateLabel,
                        priceCfa: item.priceCfa,
                        status: previous,
                        paymentStatus: item.paymentStatus,
                        locationLabel: item.locationLabel,
                        urgency: item.urgency,
                        createdAt: item.createdAt,
                        issueTitle: item.issueTitle,
                        issueSummary: item.issueSummary,
                        conversationId: item.conversationId,
                        paymentId: item.paymentId,
                        issueReportStatus: item.issueReportStatus,
                        hasReview: item.hasReview,
                      )
                    : item,
              )
              .toList()
            ..sort(_compareBookings);
        });
      }
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Operation impossible.';
    } catch (_) {
      if (mounted) {
        setState(() {
          _bookings = _bookings
              .map(
                (item) => item.id == booking.id
                    ? BookingRequest(
                        id: item.id,
                        clientName: item.clientName,
                        serviceTitle: item.serviceTitle,
                        professionalName: item.professionalName,
                        mode: item.mode,
                        dateLabel: item.dateLabel,
                        priceCfa: item.priceCfa,
                        status: previous,
                        paymentStatus: item.paymentStatus,
                        locationLabel: item.locationLabel,
                        urgency: item.urgency,
                        createdAt: item.createdAt,
                        issueTitle: item.issueTitle,
                        issueSummary: item.issueSummary,
                        conversationId: item.conversationId,
                        paymentId: item.paymentId,
                        issueReportStatus: item.issueReportStatus,
                        hasReview: item.hasReview,
                      )
                    : item,
              )
              .toList()
            ..sort(_compareBookings);
        });
      }
      return 'Operation impossible.';
    }
  }

  Future<String?> _markBookingInProgress(BookingRequest booking) async {
    if (!mounted) {
      return null;
    }
    setState(() {
      _inProgressBookingIds.add(booking.id);
    });
    return 'Dossier marque en cours.';
  }

  Future<String?> _markBookingResolved(BookingRequest booking) async {
    final previousInProgress = _inProgressBookingIds.contains(booking.id);
    if (mounted) {
      setState(() {
        _inProgressBookingIds.remove(booking.id);
        _bookings = _bookings
            .map(
              (item) => item.id == booking.id
                  ? BookingRequest(
                      id: item.id,
                      clientName: item.clientName,
                      serviceTitle: item.serviceTitle,
                      professionalName: item.professionalName,
                      mode: item.mode,
                      dateLabel: item.dateLabel,
                      priceCfa: item.priceCfa,
                      status: BookingStatus.completed,
                      paymentStatus: item.paymentStatus,
                      locationLabel: item.locationLabel,
                      urgency: item.urgency,
                      createdAt: item.createdAt,
                      issueTitle: item.issueTitle,
                      issueSummary: item.issueSummary,
                      conversationId: item.conversationId,
                      paymentId: item.paymentId,
                      issueReportStatus: item.issueReportStatus,
                      hasReview: item.hasReview,
                    )
                  : item,
            )
            .toList()
          ..sort(_compareBookings);
      });
    }

    try {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      await bookingRepository.updateBookingStatus(
        bookingId: booking.id,
        action: 'complete',
      );
      if (mounted) {
        await _syncRemoteContent();
      }
      return 'Dossier marque comme resolu.';
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          if (previousInProgress) {
            _inProgressBookingIds.add(booking.id);
          }
          _bookings = _bookings
              .map(
                (item) => item.id == booking.id
                    ? BookingRequest(
                        id: item.id,
                        clientName: item.clientName,
                        serviceTitle: item.serviceTitle,
                        professionalName: item.professionalName,
                        mode: item.mode,
                        dateLabel: item.dateLabel,
                        priceCfa: item.priceCfa,
                        status: booking.status,
                        paymentStatus: item.paymentStatus,
                        locationLabel: item.locationLabel,
                        urgency: item.urgency,
                        createdAt: item.createdAt,
                        issueTitle: item.issueTitle,
                        issueSummary: item.issueSummary,
                        conversationId: item.conversationId,
                        paymentId: item.paymentId,
                        issueReportStatus: item.issueReportStatus,
                        hasReview: item.hasReview,
                      )
                    : item,
              )
              .toList()
            ..sort(_compareBookings);
        });
      }
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Operation impossible.';
    } catch (_) {
      if (mounted) {
        setState(() {
          if (previousInProgress) {
            _inProgressBookingIds.add(booking.id);
          }
          _bookings = _bookings
              .map(
                (item) => item.id == booking.id
                    ? BookingRequest(
                        id: item.id,
                        clientName: item.clientName,
                        serviceTitle: item.serviceTitle,
                        professionalName: item.professionalName,
                        mode: item.mode,
                        dateLabel: item.dateLabel,
                        priceCfa: item.priceCfa,
                        status: booking.status,
                        paymentStatus: item.paymentStatus,
                        locationLabel: item.locationLabel,
                        urgency: item.urgency,
                        createdAt: item.createdAt,
                        issueTitle: item.issueTitle,
                        issueSummary: item.issueSummary,
                        conversationId: item.conversationId,
                        paymentId: item.paymentId,
                        issueReportStatus: item.issueReportStatus,
                        hasReview: item.hasReview,
                      )
                    : item,
              )
              .toList()
            ..sort(_compareBookings);
        });
      }
      return 'Operation impossible.';
    }
  }

  Future<String?> _reportBookingIssue(
    BookingRequest booking, {
    required String reason,
    required String details,
    required bool wantsRefund,
  }) async {
    try {
      await ref.read(bookingRepositoryProvider).reportIssue(
            bookingId: booking.id,
            reason: reason,
            details: details,
            wantsRefund: wantsRefund,
          );
      if (mounted) {
        await _syncRemoteContent();
      }
      return wantsRefund
          ? 'Signalement envoye avec demande de remboursement.'
          : 'Signalement envoye avec succes.';
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Signalement impossible.';
    } catch (_) {
      return 'Signalement impossible.';
    }
  }

  Future<String?> _submitReview(
    BookingRequest booking, {
    required int rating,
    required String comment,
  }) async {
    try {
      await ref.read(reviewsRemoteDataSourceProvider).createReview(
            bookingId: booking.id,
            rating: rating,
            comment: comment,
          );
      if (mounted) {
        await _syncRemoteContent();
      }
      return null;
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Impossible d enregistrer votre avis.';
    } catch (_) {
      return 'Impossible d enregistrer votre avis.';
    }
  }

  Future<String?> _downloadBookingReceipt(BookingRequest booking) async {
    if (booking.paymentId.isEmpty) {
      return 'Aucun recu disponible pour cette reservation.';
    }
    try {
      final bytes = await ref
          .read(bookingRepositoryProvider)
          .downloadReceipt(booking.paymentId);
      final downloaded = await downloadPdfBytes(
        bytes: bytes,
        fileName: 'recu-${booking.paymentId}.pdf',
      );
      return downloaded
          ? 'Recu PDF telecharge.'
          : 'Recu PDF genere. Le telechargement automatique n est pas disponible ici.';
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Impossible de generer le recu PDF.';
    } catch (_) {
      return 'Impossible de generer le recu PDF.';
    }
  }

  Future<void> _toggleFavorite(ServiceOffer offer) async {
    final professionalId = offer.professionalId;
    if (professionalId.isEmpty || !mounted) {
      return;
    }
    final shouldFavorite = !_favoriteProfessionalIds.contains(professionalId);
    setState(() {
      if (shouldFavorite) {
        _favoriteProfessionalIds.add(professionalId);
      } else {
        _favoriteProfessionalIds.remove(professionalId);
      }
      _offers = _offers
          .map((item) => item.professionalId == professionalId
              ? _copyOfferWithFavorite(item, shouldFavorite)
              : item)
          .toList();
    });
    try {
      await ref.read(professionalsRepositoryProvider).setFavoriteProfessional(
            professionalId: professionalId,
            isFavorite: shouldFavorite,
          );
      if (mounted) {
        await _syncRemoteContent();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (shouldFavorite) {
          _favoriteProfessionalIds.remove(professionalId);
        } else {
          _favoriteProfessionalIds.add(professionalId);
        }
        _offers = _offers
            .map((item) => item.professionalId == professionalId
                ? _copyOfferWithFavorite(item, !shouldFavorite)
                : item)
            .toList();
      });
    }
  }

  Future<PaymentInstruction?> _initiatePayment(
    BookingRequest booking,
    PaymentProvider provider,
  ) async {
    try {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final result = await bookingRepository.initiatePayment(
        bookingId: booking.id,
        provider: provider.apiValue,
        amount: booking.priceCfa.toDouble(),
      );
      final paymentId = (result['id'] ?? '').toString();
      final ussdCode = (result['ussd_code'] ?? '').toString();
      if (paymentId.isEmpty || ussdCode.isEmpty) {
        return null;
      }
      return PaymentInstruction(
        paymentId: paymentId,
        provider: provider,
        ussdCode: ussdCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _confirmPayment(String paymentId) async {
    try {
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final result =
          await bookingRepository.confirmPayment(paymentId: paymentId);
      final conversationId = (result['conversation_id'] ?? '').toString();
      if (mounted) {
        await _syncRemoteContent();
        setState(() {
          _currentIndex = 2;
          if (conversationId.isNotEmpty) {
            _selectedConversationId = conversationId;
          }
        });
      }
      return null;
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Confirmation du paiement impossible.';
    } catch (_) {
      return 'Confirmation du paiement impossible.';
    }
  }

  Future<void> _openConversation(BookingRequest booking) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentIndex = 2;
      if (booking.conversationId.isNotEmpty) {
        _selectedConversationId = booking.conversationId;
      }
    });
    await _syncRemoteContent();
  }

  Future<void> _markConversationRead(String conversationId) async {
    try {
      await ref
          .read(messagingRemoteDataSourceProvider)
          .markConversationRead(conversationId);
    } catch (_) {
      // Keep chat usable even if mark-read fails.
    }
    if (mounted) {
      await _syncRemoteContent();
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    try {
      await ref
          .read(notificationsRemoteDataSourceProvider)
          .markRead(notification.id);
    } catch (_) {
      // Keep UI navigation even if read state update fails.
    }

    if (!mounted) {
      return;
    }

    final type = notification.type.toLowerCase();
    if (type.contains('message')) {
      setState(() => _currentIndex = 2);
    } else if (type.contains('booking') || type.contains('payment')) {
      setState(() => _currentIndex = 1);
    } else {
      setState(() => _currentIndex = 4);
    }

    await _syncRemoteContent();
  }

  Future<String?> _sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final messagingRemoteDataSource =
          ref.read(messagingRemoteDataSourceProvider);
      await messagingRemoteDataSource.sendMessage(
        conversationId: conversationId,
        content: content,
      );
      if (mounted) {
        await _syncRemoteContent();
      }
      return null;
    } on DioException catch (error) {
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Envoi du message impossible.';
    } catch (_) {
      return 'Envoi du message impossible.';
    }
  }

  Future<String?> _archiveConversation(String conversationId) async {
    if (!mounted) {
      return null;
    }
    final previousArchived = _archivedConversationIds.contains(conversationId);
    final previousDeleted = _deletedConversationIds.contains(conversationId);
    setState(() {
      _archivedConversationIds.add(conversationId);
      _deletedConversationIds.remove(conversationId);
    });
    try {
      await ref
          .read(messagingRemoteDataSourceProvider)
          .archiveConversation(conversationId);
      if (mounted) {
        await _syncRemoteContent();
      }
      return 'Conversation archivee.';
    } on DioException catch (error) {
      if (mounted) {
        setState(() {
          if (!previousArchived) {
            _archivedConversationIds.remove(conversationId);
          }
          if (previousDeleted) {
            _deletedConversationIds.add(conversationId);
          }
        });
      }
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Archivage impossible.';
    } catch (_) {
      if (mounted) {
        setState(() {
          if (!previousArchived) {
            _archivedConversationIds.remove(conversationId);
          }
          if (previousDeleted) {
            _deletedConversationIds.add(conversationId);
          }
        });
      }
      return 'Archivage impossible.';
    }
  }

  Future<String?> _deleteConversation(String conversationId) async {
    if (!mounted) {
      return null;
    }
    final previousDeleted = _deletedConversationIds.contains(conversationId);
    final previousArchived = _archivedConversationIds.contains(conversationId);
    setState(() {
      _deletedConversationIds.add(conversationId);
      _archivedConversationIds.remove(conversationId);
      _conversations =
          _conversations.where((item) => item.id != conversationId).toList();
    });
    try {
      await ref
          .read(messagingRemoteDataSourceProvider)
          .deleteConversation(conversationId);
      if (mounted) {
        await _syncRemoteContent();
      }
      return 'Conversation supprimee de la liste.';
    } on DioException catch (error) {
      if (mounted) {
        await _syncRemoteContent();
        setState(() {
          if (!previousDeleted) {
            _deletedConversationIds.remove(conversationId);
          }
          if (previousArchived) {
            _archivedConversationIds.add(conversationId);
          }
        });
      }
      final payload = error.response?.data;
      if (payload is Map<String, dynamic>) {
        return payload.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      return error.message ?? 'Suppression impossible.';
    } catch (_) {
      if (mounted) {
        await _syncRemoteContent();
        setState(() {
          if (!previousDeleted) {
            _deletedConversationIds.remove(conversationId);
          }
          if (previousArchived) {
            _archivedConversationIds.add(conversationId);
          }
        });
      }
      return 'Suppression impossible.';
    }
  }

  Future<void> _logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    final session = ref.read(authSessionProvider);
    final refreshToken = session.refreshToken;

    ref.read(authSessionProvider.notifier).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      Future<void>.microtask(() async {
        try {
          await authRepository
              .logout(refreshToken)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          // Ignore remote logout failure once local session is cleared.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.admin) {
      return const AdminDashboardScreen();
    }

    final hideShellAppBar =
        widget.role == UserRole.client && _currentIndex == 0;

    final pages = <Widget>[
      widget.role == UserRole.professional
          ? ProDashboardScreen(
              profile: _myProfessionalProfile,
              offers: _offers,
              bookings: _bookings,
            )
          : FeedScreen(
              role: widget.role,
              offers: _offers,
              bookings: _bookings,
              onBook: _addBooking,
              onToggleFavorite: _toggleFavorite,
              onSubmitReview: _submitReview,
              onOpenAlerts: () {
                if (!mounted) return;
                setState(() => _currentIndex = 4);
              },
              onOpenSettings: () {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(onLogout: _logout),
                  ),
                );
              },
              onRefresh: _syncRemoteContent,
              onOpenReservations: () {
                if (!mounted) return;
                setState(() => _currentIndex = 1);
              },
            ),
      BookingsScreen(
        role: widget.role,
        bookings: _bookings,
        onOpenConversation: _openConversation,
        onRespondToBooking: _respondToBooking,
        onMarkInProgress: _markBookingInProgress,
        onMarkResolved: _markBookingResolved,
        onReportIssue: _reportBookingIssue,
        onSubmitReview: _submitReview,
        onDownloadReceipt: _downloadBookingReceipt,
        isInProgress: (bookingId) => _inProgressBookingIds.contains(bookingId),
        onInitiatePayment: _initiatePayment,
        onConfirmPayment: _confirmPayment,
      ),
      MessagesScreen(
        role: widget.role,
        conversations: _conversations,
        archivedConversationIds: _archivedConversationIds,
        deletedConversationIds: _deletedConversationIds,
        selectedConversationId: _selectedConversationId,
        onSendMessage: _sendMessage,
        onOpenConversation: _markConversationRead,
        onArchiveConversation: _archiveConversation,
        onDeleteConversation: _deleteConversation,
      ),
      widget.role == UserRole.professional
          ? ProOnboardingScreen(
              onPublishOffer: _addOffer,
              onProfileUpdated: _syncRemoteContent,
            )
          : ProfileScreen(
              bookings: _bookings,
              conversations: _conversations,
              favoriteOffers: _offers
                  .where(
                    (offer) => _favoriteProfessionalIds.contains(
                      offer.professionalId,
                    ),
                  )
                  .toList(),
            ),
      NotificationsScreen(
        notifications: _notifications,
        onOpenNotification: _openNotification,
      ),
    ];

    return Scaffold(
      appBar: hideShellAppBar
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Text(_titleForIndex()),
              surfaceTintColor: Colors.transparent,
              actions: [
                if (_usingRemoteData)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.camrlex.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        'Live',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: context.camrlex.navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Rafraichir',
                  onPressed: _isSyncing ? null : _syncRemoteContent,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Parametres',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(onLogout: _logout),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
      body: SafeArea(
        top: hideShellAppBar,
        bottom: false,
        child: KeyedSubtree(
          key: ValueKey('${widget.role.name}-$_currentIndex'),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: context.camrlex.line.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: context.camrlex.navy.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _BottomTab(
                icon: Icons.home_rounded,
                label: 'Accueil',
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomTab(
                icon: Icons.calendar_month_rounded,
                label: 'Reservations',
                selected: _currentIndex == 1,
                badgeCount: _bookingBadgeCount(),
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _BottomTab(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                selected: _currentIndex == 2,
                badgeCount: _conversations.fold<int>(
                  0,
                  (sum, item) => sum + item.unreadCount,
                ),
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _BottomTab(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                selected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _BottomTab(
                icon: Icons.notifications_none_rounded,
                label: 'Alertes',
                selected: _currentIndex == 4,
                badgeCount: _notifications.where((item) => item.isUnread).length,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForIndex() {
    switch (_currentIndex) {
      case 0:
        return widget.role == UserRole.professional
            ? 'Tableau de bord'
            : 'Accueil';
      case 1:
        return 'Reservations';
      case 2:
        return 'Messagerie';
      case 3:
        return widget.role == UserRole.professional
            ? 'Profil professionnel'
            : 'Mon compte';
      case 4:
        return 'Notifications';
      default:
        return 'DroitDirect';
    }
  }

  String _routeForIndex(int index) {
    switch (widget.role) {
      case UserRole.client:
        switch (index) {
          case 0:
            return AppRoutes.clientHome;
          case 1:
            return AppRoutes.clientBookings;
          case 2:
            return AppRoutes.clientMessages;
          case 3:
            return AppRoutes.clientProfile;
          case 4:
            return AppRoutes.clientNotifications;
        }
      case UserRole.professional:
        switch (index) {
          case 0:
            return AppRoutes.professionalHome;
          case 1:
            return AppRoutes.professionalBookings;
          case 2:
            return AppRoutes.professionalMessages;
          case 3:
            return AppRoutes.professionalProfile;
          case 4:
            return AppRoutes.professionalNotifications;
        }
      case UserRole.admin:
        return AppRoutes.adminHome;
    }

    return AppRoutes.login;
  }

  ServiceOffer _offerFromRemote(
    ServiceOfferEntity service,
    Map<String, ProfessionalProfileEntity> professionalById,
  ) {
    final professional = professionalById[service.professionalId];
    final profession = _parseProfession(professional?.professionType);
    final verificationStatus =
        _parseVerificationStatus(professional?.verificationStatus);
    final professionalCity = professional?.city ?? '';
    final professionalAddress = professional?.address ?? '';
    final professionalBio = professional?.bio ?? '';
    final professionalOffice = professional?.officeName ?? '';
    final professionalLanguages = professional?.languages ?? const <String>[];
    final professionalSpecialties =
        professional?.specialties ?? const <String>[];
    final city = service.city.isNotEmpty
        ? service.city
        : (professionalCity.isNotEmpty ? professionalCity : 'Cameroun');

    final profile = ProfessionalProfile(
      fullName: _displayNameForProfessional(professional),
      profession: profession,
      professionalNumber: professional?.professionalNumber.isNotEmpty == true
          ? professional!.professionalNumber
          : _professionalNumberFallback(profession),
      verificationStatus: verificationStatus,
      city: city,
      interventionZone: professional?.interventionZone.isNotEmpty == true
          ? professional!.interventionZone
          : (professionalCity.isNotEmpty
              ? '$professionalCity et environs'
              : 'Zone a confirmer'),
      languages: professionalLanguages.isNotEmpty
          ? professionalLanguages
          : const ['Francais'],
      bio: professionalBio.isNotEmpty
          ? professionalBio
          : 'Professionnel juridique disponible sur DroitDirect.',
      specialties: professionalSpecialties.isNotEmpty
          ? professionalSpecialties
          : const ['Conseil juridique'],
      yearsExperience: professional?.yearsExperience ?? 0,
      officeName: professionalOffice.isNotEmpty
          ? professionalOffice
          : 'Cabinet partenaire',
      address: service.address.isNotEmpty
          ? service.address
          : (professionalAddress.isNotEmpty ? professionalAddress : city),
      averageRating: professional?.ratingAverage ?? 0,
      reviews: _mapReviewsFromEntity(professional),
      canReceiveBookings: verificationStatus == VerificationStatus.verified &&
          (professional?.isActive ?? true),
      avatarUrl: professional?.avatar ?? '',
      isOnline: professional?.isOnline ?? false,
      lastSeenLabel: _formatLastSeen(professional?.lastSeenAt ?? ''),
      isFavorited: professional?.isFavorited ?? false,
    );

    return ServiceOffer(
      id: service.id,
      profile: profile,
      title: service.title,
      description: service.description.isNotEmpty
          ? service.description
          : 'Prestation juridique disponible sur demande.',
      category:
          service.category.isNotEmpty ? service.category : 'Service juridique',
      mode: _parseServiceMode(service.mode),
      feeCfa: service.amount.round(),
      durationLabel: service.durationMinutes > 0
          ? '${service.durationMinutes} min'
          : 'Selon planning',
      requiredDocuments: const ['CNI', 'Resume du dossier'],
      executionDelay: 'Selon planning',
      city: city,
      instantBooking: true,
      isPublished: service.isPublished,
      priceType: service.priceType,
      professionalId: service.professionalId,
    );
  }

  ProfessionalProfile _localProfileFromEntity(
      ProfessionalProfileEntity professional) {
    final profession = _parseProfession(professional.professionType);
    final verificationStatus =
        _parseVerificationStatus(professional.verificationStatus);
    return ProfessionalProfile(
      fullName: professional.fullName,
      profession: profession,
      professionalNumber: professional.professionalNumber.isNotEmpty
          ? professional.professionalNumber
          : _professionalNumberFallback(profession),
      verificationStatus: verificationStatus,
      city: professional.city,
      interventionZone: professional.interventionZone.isNotEmpty
          ? professional.interventionZone
          : '${professional.city} et environs',
      languages: professional.languages.isNotEmpty
          ? professional.languages
          : const ['Francais'],
      bio: professional.bio.isNotEmpty
          ? professional.bio
          : 'Professionnel juridique disponible sur DroitDirect.',
      specialties: professional.specialties.isNotEmpty
          ? professional.specialties
          : const ['Conseil juridique'],
      yearsExperience: professional.yearsExperience,
      officeName: professional.officeName.isNotEmpty
          ? professional.officeName
          : 'Cabinet partenaire',
      address: professional.address.isNotEmpty
          ? professional.address
          : professional.city,
      averageRating: professional.ratingAverage,
      reviews: professional.reviews
          .map(
            (review) => Review(
              authorName: review.authorName.isNotEmpty
                  ? review.authorName
                  : 'Client verifie',
              rating: review.rating,
              comment: review.comment,
            ),
          )
          .toList(),
      canReceiveBookings: verificationStatus == VerificationStatus.verified &&
          professional.isActive,
      avatarUrl: professional.avatar,
      isOnline: professional.isOnline,
      lastSeenLabel: _formatLastSeen(professional.lastSeenAt),
      isFavorited: professional.isFavorited,
    );
  }

  BookingRequest _bookingFromRemote(
    BookingEntity booking,
    List<ServiceOffer> offers,
  ) {
    final currentUserName =
        ref.read(authSessionProvider).user?.fullName ?? 'Utilisateur';
    ServiceOffer? offer;
    for (final item in offers) {
      if (item.id == booking.serviceId) {
        offer = item;
        break;
      }
    }
    final mode = _parseServiceMode(booking.bookingType);
    final location = mode == ServiceMode.online
        ? (booking.meetingLink.isNotEmpty
            ? booking.meetingLink
            : 'Lien de consultation a generer')
        : (booking.onsiteAddress.isNotEmpty
            ? booking.onsiteAddress
            : (offer?.profile.address ?? 'Lieu a confirmer'));

    return BookingRequest(
      id: booking.id,
      clientName:
          booking.clientName.isNotEmpty ? booking.clientName : currentUserName,
      serviceTitle: booking.serviceTitle.isNotEmpty
          ? booking.serviceTitle
          : (offer?.title ?? 'Service juridique'),
      professionalName: booking.professionalName.isNotEmpty
          ? booking.professionalName
          : (offer?.profile.fullName ?? 'Professionnel juridique'),
      mode: mode,
      dateLabel: _formatBookingDate(booking),
      priceCfa: booking.amount.round(),
      status: _parseBookingStatus(booking.status),
      paymentStatus: _parsePaymentStatus(booking.paymentStatus),
      locationLabel: location,
      urgency: _parseBookingUrgency(booking.urgency),
      createdAt: booking.createdAt,
      issueTitle: booking.issueTitle,
      issueSummary: booking.issueSummary,
      conversationId: booking.conversationId,
      paymentId: booking.paymentId,
      issueReportStatus: booking.issueReportStatus,
      hasReview: booking.hasReview,
    );
  }

  ServiceOffer _copyOfferWithFavorite(ServiceOffer offer, bool isFavorited) {
    return ServiceOffer(
      id: offer.id,
      professionalId: offer.professionalId,
      profile: ProfessionalProfile(
        fullName: offer.profile.fullName,
        profession: offer.profile.profession,
        professionalNumber: offer.profile.professionalNumber,
        verificationStatus: offer.profile.verificationStatus,
        city: offer.profile.city,
        interventionZone: offer.profile.interventionZone,
        languages: offer.profile.languages,
        bio: offer.profile.bio,
        specialties: offer.profile.specialties,
        yearsExperience: offer.profile.yearsExperience,
        officeName: offer.profile.officeName,
        address: offer.profile.address,
        averageRating: offer.profile.averageRating,
        reviews: offer.profile.reviews,
        canReceiveBookings: offer.profile.canReceiveBookings,
        avatarUrl: offer.profile.avatarUrl,
        isOnline: offer.profile.isOnline,
        lastSeenLabel: offer.profile.lastSeenLabel,
        isFavorited: isFavorited,
      ),
      title: offer.title,
      description: offer.description,
      category: offer.category,
      mode: offer.mode,
      feeCfa: offer.feeCfa,
      durationLabel: offer.durationLabel,
      requiredDocuments: offer.requiredDocuments,
      executionDelay: offer.executionDelay,
      city: offer.city,
      instantBooking: offer.instantBooking,
      isPublished: offer.isPublished,
      priceType: offer.priceType,
    );
  }

  List<Review> _mapReviewsFromEntity(ProfessionalProfileEntity? professional) {
    if (professional == null || professional.reviews.isEmpty) {
      return const [];
    }
    return professional.reviews
        .map(
          (review) => Review(
            authorName: review.authorName.isNotEmpty
                ? review.authorName
                : 'Client verifie',
            rating: review.rating,
            comment: review.comment,
          ),
        )
        .toList();
  }

  String _displayNameForProfessional(ProfessionalProfileEntity? professional) {
    if (professional == null) {
      return 'Professionnel juridique';
    }
    if (professional.fullName.isNotEmpty) {
      return professional.fullName;
    }
    return _parseProfession(professional.professionType).label;
  }

  String _formatBookingDate(BookingEntity booking) {
    final date = booking.appointmentDate;
    final start = booking.startTime;

    if (date.isEmpty && start.isEmpty) {
      return 'Date a confirmer';
    }
    if (start.isEmpty) {
      return date;
    }
    if (date.isEmpty) {
      return start;
    }
    return '$date - $start';
  }

  ConversationPreview _conversationFromRemote(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List<dynamic>?) ?? const [];
    final messages = rawMessages
        .map((item) => _chatMessageFromRemote(item as Map<String, dynamic>))
        .toList();

    return ConversationPreview(
      id: (json['id'] ?? '').toString(),
      contactName: (json['contact_name'] ?? 'Conversation').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      unreadCount: int.tryParse((json['unread_count'] ?? 0).toString()) ?? 0,
      lastActivityAt: (json['last_activity_at'] ?? '').toString(),
      messages: messages,
    );
  }

  int _compareBookings(BookingRequest a, BookingRequest b) {
    final pendingCompare =
        (b.status == BookingStatus.pending ? 1 : 0).compareTo(
      a.status == BookingStatus.pending ? 1 : 0,
    );
    if (pendingCompare != 0) {
      return pendingCompare;
    }
    final urgencyCompare = _urgencyWeight(b.urgency).compareTo(
      _urgencyWeight(a.urgency),
    );
    if (urgencyCompare != 0) {
      return urgencyCompare;
    }
    return _parseDateTimeSafe(b.createdAt)
        .compareTo(_parseDateTimeSafe(a.createdAt));
  }

  int _compareConversations(ConversationPreview a, ConversationPreview b) {
    final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
    if (unreadCompare != 0) {
      return unreadCompare;
    }
    return _parseDateTimeSafe(b.lastActivityAt)
        .compareTo(_parseDateTimeSafe(a.lastActivityAt));
  }

  int _urgencyWeight(BookingUrgency urgency) {
    switch (urgency) {
      case BookingUrgency.urgent:
        return 2;
      case BookingUrgency.medium:
        return 1;
    }
  }

  int _bookingBadgeCount() {
    if (widget.role == UserRole.professional) {
      return _bookings
          .where((booking) => booking.status == BookingStatus.pending)
          .length;
    }
    return _bookings
        .where(
          (booking) =>
              booking.status == BookingStatus.pending ||
              (booking.status == BookingStatus.accepted &&
                  booking.paymentStatus != PaymentStatus.paid),
        )
        .length;
  }

  DateTime _parseDateTimeSafe(String raw) {
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  ChatMessage _chatMessageFromRemote(Map<String, dynamic> json) {
    final sessionUserId = ref.read(authSessionProvider).user?.id;
    final attachmentUrl = (json['attachment_url'] ?? '').toString();

    return ChatMessage(
      senderName: (json['sender_name'] ?? 'DroitDirect').toString(),
      message: (json['content'] ?? '').toString(),
      sentAt: _formatRemoteTimestamp((json['created_at'] ?? '').toString()),
      isMine: (json['sender'] ?? '').toString() == (sessionUserId ?? ''),
      isRead: (json['is_read'] ?? false) == true,
      attachmentLabel: attachmentUrl.isEmpty ? null : attachmentUrl,
    );
  }

  AppNotification _notificationFromRemote(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      timeLabel: _formatRemoteTimestamp((json['created_at'] ?? '').toString()),
      isUnread: !((json['is_read'] ?? false) == true),
    );
  }

  String _formatRemoteTimestamp(String raw) {
    if (raw.isEmpty) {
      return 'A l instant';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final local = parsed.toLocal();
    final twoDigitsHour = local.hour.toString().padLeft(2, '0');
    final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $twoDigitsHour:$twoDigitsMinute';
  }

  String _formatLastSeen(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final now = DateTime.now();
    final difference = now.difference(parsed.toLocal());
    if (difference.inMinutes < 2) {
      return 'Actif a l instant';
    }
    if (difference.inMinutes < 60) {
      return 'Vu il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Vu il y a ${difference.inHours} h';
    }
    return 'Vu le ${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _professionalNumberFallback(LegalProfession profession) {
    switch (profession) {
      case LegalProfession.avocat:
        return 'Numero du barreau indisponible';
      case LegalProfession.huissier:
        return 'Numero d huissier indisponible';
      case LegalProfession.notaire:
        return 'Numero notarial indisponible';
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

  int _parseDurationMinutes(String raw) {
    final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
    return int.tryParse(digits ?? '') ?? 30;
  }

  String _verificationStatusApi(VerificationStatus status) {
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

  LegalProfession _parseProfession(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'avocat':
        return LegalProfession.avocat;
      case 'huissier':
        return LegalProfession.huissier;
      case 'notaire':
        return LegalProfession.notaire;
      default:
        return LegalProfession.avocat;
    }
  }

  VerificationStatus _parseVerificationStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'submitted':
      case 'soumis':
        return VerificationStatus.submitted;
      case 'under_review':
      case 'underreview':
      case 'en_cours':
        return VerificationStatus.underReview;
      case 'verified':
      case 'verifie':
        return VerificationStatus.verified;
      case 'rejected':
      case 'rejete':
        return VerificationStatus.rejected;
      case 'needs_completion':
      case 'a_completer':
        return VerificationStatus.needsCompletion;
      case 'suspended':
      case 'suspendu':
        return VerificationStatus.suspended;
      case 'draft':
      case 'brouillon':
      default:
        return VerificationStatus.draft;
    }
  }

  BookingStatus _parseBookingStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'accepted':
      case 'acceptee':
        return BookingStatus.accepted;
      case 'rejected':
      case 'refused':
      case 'refusee':
        return BookingStatus.refused;
      case 'cancelled':
      case 'annulee':
        return BookingStatus.cancelled;
      case 'completed':
      case 'terminee':
        return BookingStatus.completed;
      case 'expired':
      case 'expiree':
        return BookingStatus.expired;
      case 'disputed':
      case 'litige':
        return BookingStatus.disputed;
      case 'pending':
      case 'en_attente':
      default:
        return BookingStatus.pending;
    }
  }

  PaymentStatus _parsePaymentStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'paid':
      case 'paye':
        return PaymentStatus.paid;
      case 'failed':
      case 'echoue':
        return PaymentStatus.failed;
      case 'refunded':
      case 'rembourse':
        return PaymentStatus.refunded;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  BookingUrgency _parseBookingUrgency(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'urgent':
        return BookingUrgency.urgent;
      case 'medium':
      default:
        return BookingUrgency.medium;
    }
  }

  ServiceMode _parseServiceMode(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'online':
      case 'en_ligne':
        return ServiceMode.online;
      case 'onsite':
      case 'inperson':
      case 'presentiel':
        return ServiceMode.inPerson;
      case 'both':
      case 'les_deux':
      default:
        return ServiceMode.both;
    }
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 18 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? colors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? colors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colors.navy.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: selected ? Colors.white : colors.body,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB3261E),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? colors.navy : colors.body,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
