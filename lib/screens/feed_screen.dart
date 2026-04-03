import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_session_provider.dart';
import '../models.dart';
import '../theme.dart';
import 'booking_checkout_screen.dart';
import 'professional_detail_screen.dart';
import 'service_detail_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({
    super.key,
    required this.role,
    required this.offers,
    required this.bookings,
    required this.onBook,
    required this.onToggleFavorite,
    this.onSubmitReview,
    this.onOpenReservations,
    this.onOpenAlerts,
    this.onOpenSettings,
    this.onRefresh,
  });

  final UserRole role;
  final List<ServiceOffer> offers;
  final List<BookingRequest> bookings;
  final Future<String?> Function(
    ServiceOffer offer,
    ServiceMode mode,
    BookingUrgency urgency,
    String issueTitle,
    String issueSummary,
    String appointmentDate,
    String startTime,
    String endTime,
  ) onBook;
  final Future<void> Function(ServiceOffer offer) onToggleFavorite;
  final Future<String?> Function(
    BookingRequest booking, {
    required int rating,
    required String comment,
  })? onSubmitReview;
  final VoidCallback? onOpenReservations;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenSettings;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedSpecialty = 'Tous';
  int? _budgetCeiling;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<T?> _pushAnimated<T>(Widget child) {
    if (!mounted) {
      return Future<T?>.value(null);
    }
    final navigator = Navigator.of(this.context);
    return navigator.push<T>(
      PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _openBookingFlow(ServiceOffer offer) async {
    if (_hasExistingRequest(offer)) {
      widget.onOpenReservations?.call();
      return true;
    }
    final result = await _pushAnimated<bool>(
      BookingCheckoutScreen(
        offer: offer,
        onConfirm: widget.onBook,
      ),
    );

    if (!mounted || result != true) {
      return false;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colors = context.camrlex;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Commande effectuee'),
          content: Text(
            'Votre demande a bien ete envoyee.\n\n'
            'Vous allez etre redirige vers Reservations pour attendre la confirmation du professionnel. '
            'Le paiement et la discussion commenceront apres son acceptation.',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                  height: 1.45,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Voir reservations'),
            ),
          ],
        );
      },
    );
    if (!mounted) return false;
    widget.onOpenReservations?.call();
    return true;
  }

  Future<void> _openProfessionalDetail(ServiceOffer offer) async {
    final reviewableBooking = _reviewableBookingFor(offer);
    final reviewerName =
        (ref.read(authSessionProvider).user?.fullName ?? '').trim();
    await _pushAnimated<void>(
      ProfessionalDetailScreen(
        profile: offer.profile,
        featuredOffer: offer,
        onToggleFavorite: () => widget.onToggleFavorite(offer),
        canSubmitReview:
            reviewableBooking != null && widget.onSubmitReview != null,
        reviewAuthorName: reviewerName.isEmpty ? 'Vous' : reviewerName,
        onSubmitReview:
            reviewableBooking == null || widget.onSubmitReview == null
                ? null
                : (rating, comment) => widget.onSubmitReview!(
                      reviewableBooking,
                      rating: rating,
                      comment: comment,
                    ),
        onOpenService: () {
          if (!mounted) {
            return;
          }
          final navigator = Navigator.of(context);
          navigator.pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openServiceDetail(offer);
          });
        },
      ),
    );
  }

  Future<void> _openServiceDetail(ServiceOffer offer) async {
    await _pushAnimated<void>(
      ServiceDetailScreen(
        offer: offer,
        hasActiveRequest: _hasExistingRequest(offer),
        onBook: () async {
          final redirected = await _openBookingFlow(offer);
          if (!mounted || !redirected) {
            return;
          }
          Navigator.of(context).pop();
        },
        onOpenProfessional: () {
          if (!mounted) {
            return;
          }
          final navigator = Navigator.of(context);
          navigator.pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _openProfessionalDetail(offer);
          });
        },
      ),
    );
  }

  List<String> get _specialties {
    final values = <String>{'Tous'};
    for (final offer in widget.offers) {
      values.add(offer.category);
      for (final specialty in offer.profile.specialties) {
        values.add(specialty);
      }
    }
    return values.take(7).toList();
  }

  List<ServiceOffer> get _filteredOffers {
    final query = _searchQuery.trim().toLowerCase();

    return widget.offers.where((offer) {
      final matchesSpecialty = _selectedSpecialty == 'Tous' ||
          offer.category.toLowerCase() == _selectedSpecialty.toLowerCase() ||
          offer.profile.specialties.any(
            (item) => item.toLowerCase() == _selectedSpecialty.toLowerCase(),
          );

      if (!matchesSpecialty) {
        return false;
      }

      if (_budgetCeiling != null && offer.feeCfa > _budgetCeiling!) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        offer.title,
        offer.description,
        offer.category,
        offer.city,
        offer.profile.fullName,
        offer.profile.profession.label,
        ...offer.profile.specialties,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList()
      ..sort((a, b) {
        final verifiedCompare = (b.profile.canReceiveBookings ? 1 : 0)
            .compareTo(a.profile.canReceiveBookings ? 1 : 0);
        if (verifiedCompare != 0) {
          return verifiedCompare;
        }
        return b.profile.averageRating.compareTo(a.profile.averageRating);
      });
  }

  List<ServiceOffer> get _smartMatches {
    final userCity =
        (ref.read(authSessionProvider).user?.city ?? '').trim().toLowerCase();
    return [..._filteredOffers]..sort((a, b) {
        final left = _matchingScore(a, userCity);
        final right = _matchingScore(b, userCity);
        if (left != right) {
          return right.compareTo(left);
        }
        return a.feeCfa.compareTo(b.feeCfa);
      });
  }

  int _matchingScore(ServiceOffer offer, String userCity) {
    var score = 0;
    if (offer.profile.canReceiveBookings) {
      score += 40;
    }
    if (userCity.isNotEmpty && offer.city.toLowerCase() == userCity) {
      score += 24;
    }
    if (_selectedSpecialty != 'Tous') {
      if (offer.category.toLowerCase() == _selectedSpecialty.toLowerCase()) {
        score += 18;
      }
      if (offer.profile.specialties.any(
        (item) => item.toLowerCase() == _selectedSpecialty.toLowerCase(),
      )) {
        score += 18;
      }
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      if (offer.title.toLowerCase().contains(query)) {
        score += 18;
      }
      if (offer.category.toLowerCase().contains(query)) {
        score += 16;
      }
      if (offer.profile.specialties
          .any((item) => item.toLowerCase().contains(query))) {
        score += 22;
      }
      if (offer.profile.profession.label.toLowerCase().contains(query)) {
        score += 14;
      }
    }
    if (_budgetCeiling != null) {
      score += (_budgetCeiling! - offer.feeCfa).abs() <= 5000 ? 16 : 8;
    } else if (offer.feeCfa <= 25000) {
      score += 10;
    }
    if (offer.profile.averageRating >= 4.5) {
      score += 10;
    }
    if (offer.profile.isOnline) {
      score += 6;
    }
    return score;
  }

  bool _hasExistingRequest(ServiceOffer offer) {
    return widget.bookings.any((booking) {
      final sameService = booking.serviceTitle.trim().toLowerCase() ==
              offer.title.trim().toLowerCase() &&
          booking.professionalName.trim().toLowerCase() ==
              offer.profile.fullName.trim().toLowerCase();
      if (!sameService) {
        return false;
      }
      return booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.accepted;
    });
  }

  BookingRequest? _reviewableBookingFor(ServiceOffer offer) {
    final targetProfessional = offer.profile.fullName.trim().toLowerCase();
    for (final booking in widget.bookings) {
      final sameProfessional =
          booking.professionalName.trim().toLowerCase() == targetProfessional;
      if (sameProfessional &&
          booking.status == BookingStatus.completed &&
          !booking.hasReview) {
        return booking;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final session = ref.watch(authSessionProvider);
    final firstName = _firstName(session.user?.fullName);
    final featuredOffer = _smartMatches.isNotEmpty ? _smartMatches.first : null;
    final filteredOffers = _filteredOffers;
    final showingSearch = _searchQuery.trim().isNotEmpty;
    final nearbyOffers = showingSearch
        ? filteredOffers
        : filteredOffers.take(6).toList();

    return Container(
      color: const Color(0xFFF2F4F7),
      child: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
          _TopHeaderBar(
            title: showingSearch ? 'Trouver un expert' : 'Rendez-vous',
            subtitle: showingSearch
                ? '${filteredOffers.length} resultat(s) pour votre recherche'
                : 'Bonjour $firstName, choisissez votre expert juridique.',
            onOpenAlerts: widget.onOpenAlerts,
            onOpenSettings: widget.onOpenSettings,
          ),
          const SizedBox(height: 18),
          _SearchPill(
            controller: _searchController,
            hint: 'Rechercher avocat, huissier, notaire...',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 18),
          if (!showingSearch && featuredOffer != null) ...[
            _SectionHeader(
              title: 'Expert recommande',
              actionLabel: 'Voir profil',
              onAction: () => _openProfessionalDetail(featuredOffer),
            ),
            const SizedBox(height: 12),
            _HeroProfessionalCard(
              offer: featuredOffer,
              hasActiveRequest: _hasExistingRequest(featuredOffer),
              onOpenProfessional: () => _openProfessionalDetail(featuredOffer),
            ),
            const SizedBox(height: 22),
          ],
          _SectionHeader(
            title: showingSearch
                ? '${filteredOffers.length} expert(s) trouve(s)'
                : 'Choisissez votre expert',
            actionLabel: null,
            onAction: null,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _specialties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final specialty = _specialties[index];
                return _CategoryBubble(
                  label: specialty,
                  selected: specialty == _selectedSpecialty,
                  onTap: () => setState(() => _selectedSpecialty = specialty),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _BudgetPill(
                  label: 'Tous',
                  selected: _budgetCeiling == null,
                  onTap: () => setState(() => _budgetCeiling = null),
                ),
                const SizedBox(width: 8),
                _BudgetPill(
                  label: 'Jusqu a 15 000',
                  selected: _budgetCeiling == 15000,
                  onTap: () => setState(() => _budgetCeiling = 15000),
                ),
                const SizedBox(width: 8),
                _BudgetPill(
                  label: 'Jusqu a 25 000',
                  selected: _budgetCeiling == 25000,
                  onTap: () => setState(() => _budgetCeiling = 25000),
                ),
                const SizedBox(width: 8),
                _BudgetPill(
                  label: 'Jusqu a 50 000',
                  selected: _budgetCeiling == 50000,
                  onTap: () => setState(() => _budgetCeiling = 50000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (filteredOffers.isEmpty)
            _EmptySearchState(colors: colors)
          else if (showingSearch)
            ...filteredOffers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SearchResultCard(
                  offer: offer,
                  hasActiveRequest: _hasExistingRequest(offer),
                  onOpenProfessional: () => _openProfessionalDetail(offer),
                  onOpenService: () => _openServiceDetail(offer),
                  onBook: () {
                    _openBookingFlow(offer);
                  },
                  onToggleFavorite: () => widget.onToggleFavorite(offer),
                ),
              ),
            )
          else ...[
            _SectionHeader(
              title: 'Professionnels pres de vous',
              actionLabel: filteredOffers.length > nearbyOffers.length
                  ? 'Tout voir'
                  : null,
              onAction: filteredOffers.length > nearbyOffers.length
                  ? () => setState(() => _searchQuery = session.user?.city ?? '')
                  : null,
            ),
            const SizedBox(height: 12),
            _NearbyGrid(
              offers: nearbyOffers,
              hasExistingRequest: _hasExistingRequest,
              onOpenProfessional: _openProfessionalDetail,
              onOpenService: _openServiceDetail,
              onBook: _openBookingFlow,
              onToggleFavorite: widget.onToggleFavorite,
            ),
          ],
          ],
        ),
      ),
    );
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Jean';
    }
    return fullName.trim().split(' ').first;
  }
}

class _TopHeaderBar extends StatelessWidget {
  const _TopHeaderBar({
    required this.title,
    required this.subtitle,
    this.onOpenAlerts,
    this.onOpenSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.body,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              onTap: onOpenAlerts,
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(width: 10),
              _HeaderActionButton(
                icon: Icons.tune_rounded,
                onTap: onOpenSettings,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: colors.navy.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: colors.navy),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: colors.navy),
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body.withValues(alpha: 0.86),
              ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.navy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.gold : Colors.white,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.navy.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? colors.gold.withValues(alpha: 0.18)
                    : colors.mist,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _specialtyIcon(label),
                color: selected ? colors.navy : colors.navySoft,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _specialtyIcon(String label) {
    final value = label.toLowerCase();
    if (value.contains('penal') || value.contains('crimin')) {
      return Icons.gavel_rounded;
    }
    if (value.contains('fam')) {
      return Icons.family_restroom_rounded;
    }
    if (value.contains('civil')) {
      return Icons.groups_rounded;
    }
    if (value.contains('fonc') || value.contains('propr')) {
      return Icons.apartment_rounded;
    }
    if (value.contains('commercial') || value.contains('corpor')) {
      return Icons.business_center_rounded;
    }
    return Icons.balance_rounded;
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    colors.navy,
                    colors.navySoft,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colors.gold.withValues(alpha: 0.40)
                : colors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? colors.navy.withValues(alpha: 0.16)
                  : colors.navy.withValues(alpha: 0.04),
              blurRadius: selected ? 18 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_rounded,
              size: 16,
              color: selected ? colors.gold : colors.navy,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : colors.navy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroProfessionalCard extends StatelessWidget {
  const _HeroProfessionalCard({
    required this.offer,
    required this.hasActiveRequest,
    required this.onOpenProfessional,
  });

  final ServiceOffer offer;
  final bool hasActiveRequest;
  final VoidCallback onOpenProfessional;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return InkWell(
      onTap: onOpenProfessional,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.navy.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            _HeroPortrait(
              fullName: offer.profile.fullName,
              avatarUrl: offer.profile.avatarUrl,
              profession: offer.profile.profession,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.profile.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.profile.specialties.isNotEmpty
                        ? offer.profile.specialties.first
                        : offer.profile.profession.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFC8A96B),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${offer.profile.averageRating.toStringAsFixed(1)} (${offer.profile.reviews.length} avis)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.body,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusDot(
                        label: hasActiveRequest
                            ? 'Demande envoyee'
                            : (offer.profile.isOnline ? 'En ligne' : 'Profil'),
                        color: hasActiveRequest
                            ? colors.gold
                            : (offer.profile.isOnline
                                ? colors.success
                                : colors.navySoft),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, color: colors.ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyGrid extends StatelessWidget {
  const _NearbyGrid({
    required this.offers,
    required this.hasExistingRequest,
    required this.onOpenProfessional,
    required this.onOpenService,
    required this.onBook,
    required this.onToggleFavorite,
  });

  final List<ServiceOffer> offers;
  final bool Function(ServiceOffer offer) hasExistingRequest;
  final Future<void> Function(ServiceOffer offer) onOpenProfessional;
  final Future<void> Function(ServiceOffer offer) onOpenService;
  final Future<bool> Function(ServiceOffer offer) onBook;
  final Future<void> Function(ServiceOffer offer) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final columns = width >= 1040
        ? 4
        : width >= 760
            ? 3
            : 2;
    const spacing = 14.0;
    final cardWidth = (width - ((columns - 1) * spacing)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: offers
          .map(
            (offer) => SizedBox(
              width: cardWidth,
              child: _NearbyExpertCard(
                offer: offer,
                hasActiveRequest: hasExistingRequest(offer),
                onOpenProfessional: () => onOpenProfessional(offer),
                onOpenService: () => onOpenService(offer),
                onBook: () {
                  onBook(offer);
                },
                onToggleFavorite: () => onToggleFavorite(offer),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NearbyExpertCard extends StatelessWidget {
  const _NearbyExpertCard({
    required this.offer,
    required this.hasActiveRequest,
    required this.onOpenProfessional,
    required this.onOpenService,
    required this.onBook,
    required this.onToggleFavorite,
  });

  final ServiceOffer offer;
  final bool hasActiveRequest;
  final VoidCallback onOpenProfessional;
  final VoidCallback onOpenService;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final canBook = offer.profile.canReceiveBookings;
    final actionEnabled = canBook || hasActiveRequest;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpenService,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 122,
                      width: double.infinity,
                      child: _AvatarVisual(
                        avatarUrl: offer.profile.avatarUrl,
                        fullName: offer.profile.fullName,
                        profession: offer.profile.profession,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _MetaBadge(
                      icon: Icons.star_rounded,
                      label: offer.profile.averageRating.toStringAsFixed(1),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onToggleFavorite,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            offer.profile.isFavorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: offer.profile.isFavorited
                                ? const Color(0xFFD74C5D)
                                : colors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                offer.profile.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                offer.profile.specialties.isNotEmpty
                    ? offer.profile.specialties.first
                    : offer.profile.profession.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.body,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: colors.body),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      offer.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.body,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                offer.pricingLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpenProfessional,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Profil'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: actionEnabled ? onBook : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            actionEnabled ? colors.navy : colors.navySoft,
                      ),
                      child: Text(
                        hasActiveRequest ? 'Reserve' : 'Reserver',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.offer,
    required this.hasActiveRequest,
    required this.onOpenProfessional,
    required this.onOpenService,
    required this.onBook,
    required this.onToggleFavorite,
  });

  final ServiceOffer offer;
  final bool hasActiveRequest;
  final VoidCallback onOpenProfessional;
  final VoidCallback onOpenService;
  final VoidCallback onBook;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final canBook = offer.profile.canReceiveBookings;
    final actionEnabled = canBook || hasActiveRequest;
    final previewDays = _previewDays();

    return InkWell(
      onTap: onOpenService,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colors.navy.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaBadge(
                            icon: Icons.star_rounded,
                            label: offer.profile.averageRating.toStringAsFixed(1),
                          ),
                          _TagBadge(
                            label: offer.pricingLabel,
                            icon: Icons.wallet_rounded,
                            highlighted: true,
                          ),
                          _TagBadge(
                            label: offer.profile.isOnline
                                ? 'En ligne'
                                : offer.mode.label,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        offer.profile.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.profile.specialties.isNotEmpty
                            ? offer.profile.specialties.first
                            : offer.profile.profession.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.body,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasActiveRequest
                            ? 'Demande deja envoyee'
                            : (canBook
                                ? 'Disponibilites ouvertes pour reservation'
                                : 'Profil en attente de validation'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasActiveRequest
                                  ? colors.gold
                                  : (canBook ? colors.navy : colors.body),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 128,
                        height: 148,
                        child: _AvatarVisual(
                          avatarUrl: offer.profile.avatarUrl,
                          fullName: offer.profile.fullName,
                          profession: offer.profile.profession,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onToggleFavorite,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              offer.profile.isFavorited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: offer.profile.isFavorited
                                  ? const Color(0xFFD74C5D)
                                  : colors.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = previewDays[index];
                  return _DayCapsule(
                    day: day,
                    selected: index == 3,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenProfessional,
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Profil'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: actionEnabled ? onBook : null,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(
                      hasActiveRequest ? 'Reserve' : 'Reserver',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.colors,
  });

  final CamrlexColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: colors.navySoft),
          const SizedBox(height: 12),
          Text(
            'Aucun professionnel ne correspond a votre recherche.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez une autre specialite, une autre ville ou retirez le filtre budget.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait({
    required this.fullName,
    required this.avatarUrl,
    required this.profession,
  });

  final String fullName;
  final String avatarUrl;
  final LegalProfession profession;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 108,
        height: 108,
        child: _AvatarVisual(
          avatarUrl: avatarUrl,
          fullName: fullName,
          profession: profession,
        ),
      ),
    );
  }
}

class _AvatarVisual extends StatelessWidget {
  const _AvatarVisual({
    required this.avatarUrl,
    required this.fullName,
    required this.profession,
  });

  final String avatarUrl;
  final String fullName;
  final LegalProfession profession;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final image = avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE2ECF7),
            colors.mist,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: image == null
            ? null
            : DecorationImage(
                image: image,
                fit: BoxFit.cover,
              ),
      ),
      child: image != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colors.navy.withValues(alpha: 0.16),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(fullName, profession),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
    );
  }

  String _initials(String value, LegalProfession profession) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return profession.label.substring(0, 1).toUpperCase();
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: highlighted
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFF5D4),
                  colors.mist,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : colors.mist,
        border: Border.all(
          color: highlighted
              ? colors.gold.withValues(alpha: 0.24)
              : colors.line.withValues(alpha: 0.75),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: highlighted ? colors.gold : colors.body,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlighted ? colors.navy : colors.body,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DayCapsule extends StatelessWidget {
  const _DayCapsule({
    required this.day,
    required this.selected,
  });

  final DateTime day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 58,
      decoration: BoxDecoration(
        color: selected ? colors.navy : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? colors.navy : colors.line,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekday(day.weekday),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white70 : colors.body,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}'.padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : colors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  String _weekday(int value) {
    switch (value) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mer';
      case DateTime.thursday:
        return 'Jeu';
      case DateTime.friday:
        return 'Ven';
      case DateTime.saturday:
        return 'Sam';
      default:
        return 'Dim';
    }
  }
}

List<DateTime> _previewDays() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return List<DateTime>.generate(6, (index) => start.add(Duration(days: index)));
}
