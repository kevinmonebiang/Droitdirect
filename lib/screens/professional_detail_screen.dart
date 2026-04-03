import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  const ProfessionalDetailScreen({
    super.key,
    required this.profile,
    this.featuredOffer,
    this.onToggleFavorite,
    this.onOpenService,
    this.onSubmitReview,
    this.canSubmitReview = false,
    this.reviewAuthorName = 'Vous',
  });

  final ProfessionalProfile profile;
  final ServiceOffer? featuredOffer;
  final Future<void> Function()? onToggleFavorite;
  final VoidCallback? onOpenService;
  final Future<String?> Function(int rating, String comment)? onSubmitReview;
  final bool canSubmitReview;
  final String reviewAuthorName;

  @override
  State<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  late bool _isFavorited;
  late List<Review> _reviews;
  late double _averageRating;
  late bool _canSubmitReview;
  bool _isTogglingFavorite = false;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.profile.isFavorited;
    _reviews = List<Review>.from(widget.profile.reviews);
    _averageRating = widget.profile.averageRating;
    _canSubmitReview = widget.canSubmitReview;
  }

  Future<void> _handleToggleFavorite() async {
    if (widget.onToggleFavorite == null || _isTogglingFavorite) {
      return;
    }
    final previous = _isFavorited;
    setState(() {
      _isFavorited = !previous;
      _isTogglingFavorite = true;
    });
    try {
      await widget.onToggleFavorite!.call();
    } catch (_) {
      if (mounted) {
        setState(() => _isFavorited = previous);
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  Future<void> _openReviewComposer() async {
    if (!_canSubmitReview ||
        _isSubmittingReview ||
        widget.onSubmitReview == null) {
      return;
    }

    final result = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReviewComposerSheet(
        initialAuthorName: widget.reviewAuthorName,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() => _isSubmittingReview = true);
    final message =
        await widget.onSubmitReview!.call(result.rating, result.comment);
    if (!mounted) {
      return;
    }

    setState(() => _isSubmittingReview = false);

    if (message == null) {
      final nextReviews = <Review>[
        Review(
          authorName: widget.reviewAuthorName,
          rating: result.rating.toDouble(),
          comment: result.comment,
        ),
        ..._reviews,
      ];
      setState(() {
        _reviews = nextReviews;
        _averageRating = _computeAverageRating(nextReviews);
        _canSubmitReview = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avis enregistre avec succes.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double _computeAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<double>(
      0,
      (sum, item) => sum + item.rating,
    );
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final previewDays = _previewDays();
    final featuredOffer = widget.featuredOffer;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Details du professionnel'),
        actions: [
          if (widget.onToggleFavorite != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _isTogglingFavorite
                    ? null
                    : () => _handleToggleFavorite(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.navy,
                ),
                icon: Icon(
                  _isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE4F1FB), Color(0xFFF6F8FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RatingCaption(
                  rating: _averageRating,
                  count: _reviews.length,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                  height: 1.04,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.profile.specialties.isNotEmpty
                                ? widget.profile.specialties.first
                                : widget.profile.profession.label,
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
                              _CircleAction(
                                icon: _isFavorited
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: _isTogglingFavorite
                                    ? null
                                    : () => _handleToggleFavorite(),
                              ),
                              const SizedBox(width: 10),
                              _CircleAction(
                                icon: Icons.calendar_month_rounded,
                                onTap: widget.onOpenService,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            featuredOffer?.pricingLabel ?? 'Tarif sur demande',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            featuredOffer == null
                                ? 'selon dossier'
                                : featuredOffer.isFree
                                    ? 'consultation gratuite'
                                    : featuredOffer.isPricedAfterReview
                                        ? 'honoraires fixes apres etude'
                                        : '/prestation',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.body),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ProfileHeroImage(
                      fullName: widget.profile.fullName,
                      avatarUrl: widget.profile.avatarUrl,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'A propos',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${widget.profile.yearsExperience}+ ans',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            child: Text(
              widget.profile.bio.isNotEmpty
                  ? widget.profile.bio
                  : 'Professionnel juridique verifie, disponible pour accompagner vos besoins avec clarte et discretion.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.body,
                    height: 1.55,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Disponibilites visuelles',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.profile.city,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le choix final du creneau se fait dans le parcours de reservation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.body,
                      ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 70,
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
          _InfoCard(
            title: 'Identite professionnelle',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoTag(
                  icon: Icons.balance_rounded,
                  label: widget.profile.profession.label,
                ),
                _InfoTag(
                  icon: Icons.badge_outlined,
                  label: widget.profile.professionalNumber,
                ),
                _InfoTag(
                  icon: Icons.apartment_rounded,
                  label: widget.profile.officeName,
                ),
                _InfoTag(
                  icon: Icons.record_voice_over_rounded,
                  label: widget.profile.languages.join(', '),
                ),
              ],
            ),
          ),
          if (widget.featuredOffer != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Service recommande',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.featuredOffer!.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.featuredOffer!.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: widget.onOpenService,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Voir le service'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Avis verifies',
            trailing: _canSubmitReview
                ? FilledButton.tonalIcon(
                    onPressed:
                        _isSubmittingReview ? null : () => _openReviewComposer(),
                    icon: _isSubmittingReview
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rate_review_rounded),
                    label: Text(
                      _isSubmittingReview ? 'Envoi...' : 'Commenter',
                    ),
                  )
                : null,
            child: _reviews.isEmpty
                ? Text(
                    'Aucun avis verifie disponible pour le moment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.body,
                        ),
                  )
                : Column(
                    children: _reviews.map((review) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    review.authorName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Text(
                                  review.rating.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: colors.gold,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.comment,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.body,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: FilledButton(
          onPressed: widget.onOpenService,
          style: FilledButton.styleFrom(
            backgroundColor: colors.navy,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text('Voir le service et reserver'),
        ),
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({
    required this.rating,
    required this.comment,
  });

  final int rating;
  final String comment;
}

class _ReviewComposerSheet extends StatefulWidget {
  const _ReviewComposerSheet({
    required this.initialAuthorName,
  });

  final String initialAuthorName;

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  late final TextEditingController _commentController;
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre avis verifie',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.ink,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Publie depuis ${widget.initialAuthorName}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.body,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFB547),
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  hintText:
                      'Decrivez votre experience avec ce professionnel.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final comment = _commentController.text.trim();
                        if (comment.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ajoutez un commentaire un peu plus detaille.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          _ReviewDraft(
                            rating: _rating,
                            comment: comment,
                          ),
                        );
                      },
                      child: const Text('Publier'),
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

class _ProfileHeroImage extends StatelessWidget {
  const _ProfileHeroImage({
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 156,
        height: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD9EBF8), Color(0xFFF7F8FB)],
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
        child: image == null
            ? Center(
                child: Text(
                  _initials(fullName),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              )
            : DecoratedBox(
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
              ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
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

class _RatingCaption extends StatelessWidget {
  const _RatingCaption({
    required this.rating,
    required this.count,
  });

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFC8A96B), size: 18),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($count avis)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.camrlex.body,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.camrlex.navy,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
        borderRadius: BorderRadius.circular(28),
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

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.camrlex.navy),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(22),
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
