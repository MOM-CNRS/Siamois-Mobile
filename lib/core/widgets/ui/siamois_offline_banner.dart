import 'package:flutter/material.dart';

import '../../sync/app_sync_status_scope.dart';
import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// Bandeau orange affiché sous la barre de recherche quand l’app est hors ligne.
class SiamoisOfflineBanner extends StatelessWidget {
  const SiamoisOfflineBanner({
    super.key,
    this.detail,
    this.edgeToEdge = true,
  });

  /// Message affiché sur une seule ligne (sans titre).
  final String? detail;

  /// Pleine largeur (sans marge latérale) pour l’aligner sous la barre de recherche.
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) {
    final scope = AppSyncStatusScope.maybeOf(context);
    if (scope?.notifier == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: scope!.notifier!,
      builder: (context, _) {
        if (scope.notifier!.isConnected) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final message = (detail != null && detail!.trim().isNotEmpty)
            ? detail!.trim()
            : 'Les données affichées proviennent du cache local.';

        final banner = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: SiamoisSpacing.md,
            vertical: SiamoisSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: SiamoisColors.warning.withValues(alpha: 0.12),
            border: Border(
              bottom: BorderSide(
                color: SiamoisColors.warning.withValues(alpha: 0.28),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: SiamoisColors.warning,
                size: 18,
              ),
              const SizedBox(width: SiamoisSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: SiamoisColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        if (edgeToEdge) return banner;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            SiamoisSpacing.pageHorizontal,
            SiamoisSpacing.sm,
            SiamoisSpacing.pageHorizontal,
            0,
          ),
          child: banner,
        );
      },
    );
  }
}
