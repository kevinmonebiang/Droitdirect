import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class CamrlexHeroCard extends StatelessWidget {
  const CamrlexHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.dark = false,
    this.children = const [],
  });

  final String eyebrow;
  final String title;
  final String description;
  final bool dark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;
    final panelGradient = LinearGradient(
      colors:
          dark ? [colors.navy, colors.navySoft] : [colors.panel, colors.mist],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: panelGradient,
        borderRadius: BorderRadius.circular(30),
        border: dark ? null : Border.all(color: colors.line),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : colors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: dark ? Colors.white : colors.navy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: dark ? Colors.white : colors.ink,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: dark ? Colors.white.withValues(alpha: 0.82) : colors.body,
                  height: 1.45,
                ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: children,
            ),
          ],
        ],
      ),
    );
  }
}

class CamrlexSectionCard extends StatelessWidget {
  const CamrlexSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.body,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class CamrlexInfoChip extends StatelessWidget {
  const CamrlexInfoChip({
    super.key,
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
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.navy),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class CamrlexStatusBadge extends StatelessWidget {
  const CamrlexStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class CamrlexMetricCard extends StatelessWidget {
  const CamrlexMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.body,
                ),
          ),
        ],
      ),
    );
  }
}

class CamrlexStars extends StatelessWidget {
  const CamrlexStars({
    super.key,
    required this.rating,
    this.size = 18,
  });

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.camrlex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final icon = rating >= starValue
            ? Icons.star_rounded
            : rating >= starValue - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;

        return Icon(
          icon,
          size: size,
          color: colors.gold,
        );
      }),
    );
  }
}

IconData professionIcon(LegalProfession profession) {
  switch (profession) {
    case LegalProfession.avocat:
      return Icons.balance_outlined;
    case LegalProfession.huissier:
      return Icons.gavel_rounded;
    case LegalProfession.notaire:
      return Icons.approval_outlined;
  }
}

Color verificationColor(
  VerificationStatus status,
  CamrlexColors colors,
) {
  switch (status) {
    case VerificationStatus.verified:
      return colors.success;
    case VerificationStatus.submitted:
    case VerificationStatus.underReview:
      return colors.navySoft;
    case VerificationStatus.needsCompletion:
      return colors.gold;
    case VerificationStatus.rejected:
    case VerificationStatus.suspended:
      return const Color(0xFFB3261E);
    case VerificationStatus.draft:
      return colors.body;
  }
}
