import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    super.key,
    required this.offer,
    this.hasActiveRequest = false,
    required this.onBook,
    required this.onOpenProfessional,
  });

  final ServiceOffer offer;
  final bool hasActiveRequest;
  final Future<void> Function() onBook;
  final VoidCallback onOpenProfessional;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final previewDays = _previewDays();
    final canReceiveBookings = offer.profile.canReceiveBookings;
    final actionEnabled = canReceiveBookings || hasActiveRequest;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Details du service'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 126),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDDF0FF), Color(0xFFF6F9FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.07),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroMetaPill(
                      icon: Icons.star_rounded,
                      label:
                          '${offer.profile.averageRating.toStringAsFixed(1)} (${offer.profile.reviews.length} avis)',
                    ),
                    const Spacer(),
                    _HeroActionButton(
                      icon: Icons.person_outline_rounded,
                      onTap: onOpenProfessional,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.profile.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            offer.profile.specialties.isNotEmpty
                                ? offer.profile.specialties.first
                                : offer.profile.profession.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: colors.body,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _HeroActionButton(
                                icon: Icons.balance_rounded,
                                filled: true,
                                onTap: onOpenProfessional,
                              ),
                              const SizedBox(width: 10),
                              _HeroActionButton(
                                icon: Icons.calendar_month_rounded,
                                filled: true,
                                onTap: actionEnabled ? () => onBook() : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            offer.pricingLabel,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            offer.isFree
                                ? 'consultation offerte'
                                : offer.isPricedAfterReview
                                    ? 'honoraires fixes apres etude'
                                    : '/${offer.durationLabel}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.body),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ServiceHeroVisual(
                      fullName: offer.profile.fullName,
                      avatarUrl: offer.profile.avatarUrl,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            title: 'A propos du service',
            trailing: _InlineCapsule(label: offer.category),
            child: Text(
              offer.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.body,
                    height: 1.58,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            title: 'Informations pratiques',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoCapsule(
                  icon: Icons.video_call_outlined,
                  label: offer.mode.label,
                ),
                _InfoCapsule(
                  icon: Icons.schedule_rounded,
                  label: offer.durationLabel,
                ),
                _InfoCapsule(
                  icon: Icons.flash_on_rounded,
                  label: offer.executionDelay,
                ),
                _InfoCapsule(
                  icon: Icons.place_outlined,
                  label: offer.city,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            title: 'Creer votre planning',
            trailing: _InlineCapsule(label: 'Cette semaine'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisissez ensuite le creneau final au moment de la reservation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.body,
                      ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: previewDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _DayPill(
                        day: previewDays[index],
                        selected: index == 3,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            title: 'Professionnel associe',
            child: Row(
              children: [
                _MiniAvatar(
                  fullName: offer.profile.fullName,
                  avatarUrl: offer.profile.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.profile.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${offer.profile.profession.label} - ${offer.profile.officeName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.body,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.profile.canReceiveBookings
                            ? 'Disponible pour de nouvelles demandes'
                            : 'Disponible apres validation admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: offer.profile.canReceiveBookings
                                  ? colors.success
                                  : colors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onOpenProfessional,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Profil'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SurfaceCard(
            title: 'Documents requis',
            child: offer.requiredDocuments.isEmpty
                ? Text(
                    'Aucun document obligatoire avant le premier echange avec le professionnel.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                          height: 1.5,
                        ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: offer.requiredDocuments
                        .map(
                          (item) => _InfoCapsule(
                            icon: Icons.description_outlined,
                            label: item,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDE3F8),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    hasActiveRequest
                        ? 'Votre demande est deja envoyee. Suivez-la dans Reservations.'
                        : (canReceiveBookings
                            ? 'Passez a l etape suivante pour reserver cette prestation.'
                            : 'Le service deviendra reservable apres validation du compte professionnel.'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: _SwipeBookingBar(
          enabled: actionEnabled,
          label: hasActiveRequest
              ? 'Glissez pour voir la reservation'
              : (canReceiveBookings
                  ? 'Glissez pour reserver'
                  : 'Disponible apres validation'),
          icon: hasActiveRequest
              ? Icons.calendar_month_rounded
              : Icons.arrow_forward_rounded,
          onComplete: onBook,
        ),
      ),
    );
  }
}

class _SwipeBookingBar extends StatefulWidget {
  const _SwipeBookingBar({
    required this.enabled,
    required this.label,
    required this.icon,
    required this.onComplete,
  });

  final bool enabled;
  final String label;
  final IconData icon;
  final Future<void> Function() onComplete;

  @override
  State<_SwipeBookingBar> createState() => _SwipeBookingBarState();
}

class _SwipeBookingBarState extends State<_SwipeBookingBar> {
  double _dragOffset = 0;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 54.0;
        final trackWidth = constraints.maxWidth;
        final maxOffset =
            trackWidth - knobSize - 8 <= 0 ? 0.0 : trackWidth - knobSize - 8;
        final progress = maxOffset == 0
            ? 0.0
            : (_dragOffset / maxOffset).clamp(0.0, 1.0).toDouble();

        return Container(
          height: 74,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(37),
            boxShadow: [
              BoxShadow(
                color: colors.navy.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 72),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: widget.enabled ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              if (widget.enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: knobSize + (_dragOffset * 0.9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D2C4B).withValues(
                            alpha: 0.18 + (progress * 0.18),
                          ),
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 4 + _dragOffset,
                child: GestureDetector(
                  onHorizontalDragUpdate: !widget.enabled || _submitting
                      ? null
                      : (details) {
                          setState(() {
                            _dragOffset = (_dragOffset + details.delta.dx)
                                .clamp(0.0, maxOffset)
                                .toDouble();
                          });
                        },
                  onHorizontalDragEnd: !widget.enabled || _submitting
                      ? null
                      : (_) async {
                          final shouldComplete = progress >= 0.72;
                          if (!shouldComplete) {
                            setState(() => _dragOffset = 0);
                            return;
                          }
                          setState(() {
                            _dragOffset = maxOffset;
                            _submitting = true;
                          });
                          try {
                            await widget.onComplete();
                          } finally {
                            if (mounted) {
                              setState(() {
                                _submitting = false;
                                _dragOffset = 0;
                              });
                            }
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? const Color(0xFFBDE3F8)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(27),
                    ),
                    child: _submitting
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: colors.navy,
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: widget.enabled ? colors.navy : Colors.white70,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: widget.enabled ? Colors.white : Colors.white54,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceHeroVisual extends StatelessWidget {
  const _ServiceHeroVisual({
    required this.fullName,
    required this.avatarUrl,
  });

  final String fullName;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final image = avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 158,
        height: 260,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD7EBF9), Color(0xFFF7F9FC)],
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
                      colors.navy.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              )
            : Center(
                child: Text(
                  _initials(fullName),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'D';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Material(
      color: filled ? colors.navy : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Icon(
            icon,
            size: 20,
            color: filled ? Colors.white : colors.navy,
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.camrlex.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InlineCapsule extends StatelessWidget {
  const _InlineCapsule({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.camrlex.navy,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InfoCapsule extends StatelessWidget {
  const _InfoCapsule({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.navy),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.fullName,
    required this.avatarUrl,
  });

  final String fullName;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final image = avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null;
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFD6EBF9),
      backgroundImage: image,
      child: image == null
          ? Text(
              _initials(fullName),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.camrlex.navy,
                    fontWeight: FontWeight.w900,
                  ),
            )
          : null,
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'D';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
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
      width: 64,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFBDE3F8) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekday(day.weekday),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? colors.navy : colors.body,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}'.padLeft(2, '0'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.ink,
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
  return List<DateTime>.generate(5, (index) => start.add(Duration(days: index)));
}
