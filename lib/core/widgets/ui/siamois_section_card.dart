import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// Carte d'en-tête pour les écrans de détail (fiche projet / UE).
class SiamoisSectionCard extends StatelessWidget {
  const SiamoisSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.footer,
    this.child,
  });

  final String title;
  final String? subtitle;
  final String? footer;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiamoisSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SiamoisColors.primaryContainer,
            SiamoisColors.surfaceCard,
            SiamoisColors.accentMuted,
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusXl),
        border: Border.all(color: SiamoisColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: SiamoisColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SiamoisColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (footer != null && footer!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SiamoisSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: SiamoisColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusSm),
              ),
              child: Text(
                footer!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: SiamoisColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: SiamoisSpacing.md),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Titre de section dans les formulaires.
class SiamoisFormSectionHeader extends StatelessWidget {
  const SiamoisFormSectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SiamoisColors.accentLight,
                  SiamoisColors.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: SiamoisColors.primaryDark,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
