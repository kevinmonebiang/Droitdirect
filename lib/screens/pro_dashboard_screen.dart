import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class ProDashboardScreen extends StatelessWidget {
  const ProDashboardScreen({
    super.key,
    required this.profile,
    required this.offers,
    required this.bookings,
  });

  final ProfessionalProfile? profile;
  final List<ServiceOffer> offers;
  final List<BookingRequest> bookings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.camrlex;
    final pendingBookings =
        bookings.where((item) => item.status == BookingStatus.pending).length;
    final todayBookings = bookings
        .where((item) => item.dateLabel.toLowerCase().contains('aujourd'))
        .length;
    final totalRevenue = bookings
        .where(
          (item) =>
              item.status == BookingStatus.accepted ||
              item.status == BookingStatus.completed,
        )
        .fold<int>(0, (sum, item) => sum + item.priceCfa);
    final publishedOffers = offers.where((item) => item.isPublished).length;
    final draftOffers = offers.length - publishedOffers;
    final verificationProgress =
        _verificationProgress(profile?.verificationStatus);

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  colors: [colors.navy, colors.navySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.navy.withValues(alpha: 0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      profile?.isOnline == true
                          ? 'Professionnel en ligne'
                          : 'Espace professionnel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile == null
                        ? 'Configurez votre presence pro.'
                        : 'Bonjour ${profile!.fullName.split(' ').first}, pilotez votre activite.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile == null
                        ? 'Ajoutez votre identite, soumettez vos documents puis publiez vos offres.'
                        : '${profile!.profession.label} - ${profile!.city} - ${profile!.verificationStatus.label}',
                    style: const TextStyle(
                      color: Color(0xFFD9E4F3),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification',
                                style: TextStyle(
                                  color: Color(0xFFD9E4F3),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(verificationProgress * 100).round()}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: verificationProgress,
                              minHeight: 10,
                              backgroundColor: const Color(0x305E7394),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFC8A96B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Vue d ensemble',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces chiffres viennent de vos offres et reservations reelles.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.body,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  label: 'Reservations',
                  value: '${bookings.length}',
                  accent: const Color(0xFFE9F0F8),
                  icon: Icons.calendar_month_rounded,
                ),
                _MetricCard(
                  label: 'Revenus',
                  value: '$totalRevenue FCFA',
                  accent: const Color(0xFFF8F2E8),
                  icon: Icons.payments_outlined,
                ),
                _MetricCard(
                  label: 'En attente',
                  value: '$pendingBookings',
                  accent: const Color(0xFFFFF3E1),
                  icon: Icons.schedule_outlined,
                ),
                _MetricCard(
                  label: 'Aujourd hui',
                  value: '$todayBookings RDV',
                  accent: const Color(0xFFE8F7EF),
                  icon: Icons.event_available_outlined,
                ),
                _MetricCard(
                  label: 'Offres publiees',
                  value: '$publishedOffers',
                  accent: const Color(0xFFFFF6D9),
                  icon: Icons.campaign_outlined,
                ),
                _MetricCard(
                  label: 'Brouillons',
                  value: '$draftOffers',
                  accent: const Color(0xFFEAF1F9),
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etat du profil',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionTile(
                    icon: Icons.verified_user_outlined,
                    title:
                        profile?.verificationStatus.label ?? 'Profil non configure',
                    subtitle: profile == null
                        ? 'Commencez par renseigner votre identite professionnelle.'
                        : profile!.canReceiveBookings
                            ? 'Votre compte peut deja recevoir des reservations.'
                            : 'Les reservations seront debloquees apres validation admin.',
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.circle_rounded,
                    title: profile?.isOnline == true
                        ? 'Visible en ligne'
                        : 'Hors ligne',
                    subtitle: profile == null
                        ? 'Votre presence apparaitra apres creation du profil.'
                        : profile!.isOnline
                            ? 'Les clients vous voient comme disponible.'
                            : (profile!.lastSeenLabel.isNotEmpty
                                ? profile!.lastSeenLabel
                                : 'Aucune activite recente detectee.'),
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.location_on_outlined,
                    title: profile?.interventionZone.isNotEmpty == true
                        ? profile!.interventionZone
                        : 'Zone d intervention non renseignee',
                    subtitle: profile == null
                        ? 'Ajoutez votre ville et votre zone d intervention.'
                        : '${profile!.officeName} - ${profile!.address}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos services',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (offers.isEmpty)
                    Text(
                      'Aucune offre enregistree pour le moment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.body,
                      ),
                    )
                  else
                    ...offers.take(3).map(
                      (offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MiniStatRow(
                          title: offer.title,
                          subtitle: offer.isPublished
                              ? '${offer.pricingLabel} - visible sur le feed'
                              : '${offer.pricingLabel} - brouillon en attente',
                          progress: offer.isPublished ? 1 : 0.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _verificationProgress(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
        return 1;
      case VerificationStatus.underReview:
      case VerificationStatus.submitted:
        return 0.72;
      case VerificationStatus.needsCompletion:
        return 0.45;
      case VerificationStatus.rejected:
      case VerificationStatus.suspended:
        return 0.25;
      case VerificationStatus.draft:
        return 0.12;
      case null:
        return 0;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colors.line),
          boxShadow: [
            BoxShadow(
              color: colors.navy.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colors.navy),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.body,
              ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: colors.mist,
            valueColor: AlwaysStoppedAnimation<Color>(colors.gold),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.mist,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: colors.navy),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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
      ],
    );
  }
}
