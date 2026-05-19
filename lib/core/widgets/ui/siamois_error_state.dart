import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// État d’erreur avec action de réessai.
class SiamoisErrorState extends StatelessWidget {
  const SiamoisErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Une erreur est survenue',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SiamoisSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: SiamoisColors.error.withValues(alpha: 0.9),
              ),
              const SizedBox(height: SiamoisSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: SiamoisColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
