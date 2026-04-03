import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/providers/repository_providers.dart';
import '../features/auth/presentation/providers/auth_session_provider.dart';
import '../models.dart';
import '../theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.bookings = const [],
    this.conversations = const [],
    this.favoriteOffers = const [],
  });

  final List<BookingRequest> bookings;
  final List<ConversationPreview> conversations;
  final List<ServiceOffer> favoriteOffers;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  PlatformFile? _avatarFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _avatarFile = result.files.first);
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final sessionUser = ref.read(authSessionProvider).user;
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final nothingChanged = _avatarFile == null &&
        sessionUser != null &&
        sessionUser.fullName == fullName &&
        sessionUser.phone == phone &&
        sessionUser.city == city;

    if (fullName.length < 3 || phone.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez correctement le nom complet et le telephone.'),
        ),
      );
      return;
    }

    if (nothingChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune modification detectee.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final updatedUser = await authRepository.updateMe(
        fullName: fullName,
        phone: phone,
        city: city,
        avatarFile: _avatarFile,
      );
      ref.read(authSessionProvider.notifier).updateUser(updatedUser);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour.')),
      );
      setState(() => _avatarFile = null);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? payload.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' | ')
          : 'Impossible de mettre a jour le profil.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre a jour le profil.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final user = ref.watch(authSessionProvider).user;
    final activeBookings = widget.bookings
        .where((item) => item.status != BookingStatus.completed)
        .toList();
    final paidBookings = widget.bookings
        .where((item) => item.paymentStatus == PaymentStatus.paid)
        .length;
    final unreadMessages = widget.conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.navy,
                  colors.navySoft,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                           
                          ),
                          const SizedBox(width: 14),
                          
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Stack(
                      children: [
                        _AvatarPreview(
                          imageUrl: user?.avatar ?? '',
                          localFile: _avatarFile,
                          fullName: user?.fullName ?? 'Utilisateur',
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _pickAvatar,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Compte utilisateur',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.82),
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
          const SizedBox(height: 18),
          _FormCard(
            title: 'Informations personnelles',
            child: Column(
              children: [
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telephone',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Enregistrement...' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _FormCard(
            title: 'Dossier juridique',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DossierMetric(
                      label: 'Rendez-vous',
                      value: '${widget.bookings.length}',
                      icon: Icons.calendar_month_rounded,
                    ),
                    _DossierMetric(
                      label: 'Paiements confirmes',
                      value: '$paidBookings',
                      icon: Icons.payments_rounded,
                    ),
                    _DossierMetric(
                      label: 'Messages non lus',
                      value: '$unreadMessages',
                      icon: Icons.mark_chat_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Dossiers actifs',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (activeBookings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.mist,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Vos futurs dossiers, rendez-vous et paiements regroupes apparaitront ici.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.body,
                          ),
                    ),
                  )
                else
                  ...activeBookings.take(4).map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DossierCard(booking: booking),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Echanges recents',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (widget.conversations.isEmpty)
                  Text(
                    'Aucune conversation pour le moment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                        ),
                  )
                else
                  ...widget.conversations.take(3).map(
                    (conversation) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.mist,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colors.navy.withValues(alpha: 0.08),
                              child: Text(
                                conversation.contactName.isEmpty
                                    ? 'D'
                                    : conversation.contactName[0].toUpperCase(),
                                style: TextStyle(
                                  color: colors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conversation.contactName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    conversation.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: colors.body),
                                  ),
                                ],
                              ),
                            ),
                            if (conversation.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.gold,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _FormCard(
            title: 'Professionnels suivis',
            child: widget.favoriteOffers.isEmpty
                ? Text(
                    'Ajoutez vos professionnels preferes pour les retrouver rapidement ici.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                        ),
                  )
                : Column(
                    children: widget.favoriteOffers.take(4).map((offer) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.mist,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    colors.navy.withValues(alpha: 0.08),
                                backgroundImage: offer.profile.avatarUrl.isNotEmpty
                                    ? NetworkImage(offer.profile.avatarUrl)
                                    : null,
                                child: offer.profile.avatarUrl.isEmpty
                                    ? Text(
                                        offer.profile.fullName.substring(0, 1),
                                        style: TextStyle(
                                          color: colors.navy,
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
                                      offer.profile.fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${offer.profile.profession.label} - ${offer.city}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.body),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.favorite_rounded, color: colors.gold),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageUrl,
    required this.localFile,
    required this.fullName,
  });

  final String imageUrl;
  final PlatformFile? localFile;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final initials = fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    ImageProvider? provider;
    if (localFile?.bytes != null) {
      provider = MemoryImage(localFile!.bytes!);
    } else if (imageUrl.isNotEmpty) {
      provider = NetworkImage(imageUrl);
    }

    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      backgroundImage: provider,
      child: provider == null
          ? Text(
              initials.isEmpty ? 'U' : initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            )
          : null,
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DossierMetric extends StatelessWidget {
  const _DossierMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.mist,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.navy),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.navy,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.body,
                ),
          ),
        ],
      ),
    );
  }
}

class _DossierCard extends StatelessWidget {
  const _DossierCard({required this.booking});

  final BookingRequest booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.issueTitle.isEmpty ? booking.serviceTitle : booking.issueTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.navy,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(
                    color: colors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Professionnel: ${booking.professionalName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rendez-vous: ${booking.dateLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paiement: ${booking.paymentStatus.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                ),
          ),
        ],
      ),
    );
  }
}
