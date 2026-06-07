import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../sync/app_sync_status_scope.dart';
import 'siamois_connection_mode_chip.dart';
import 'siamois_sync_queue_badge.dart';

/// Bandeau connexion + badge file d’attente (barre de titre).
class SiamoisAppBarSyncStrip extends StatelessWidget {
  const SiamoisAppBarSyncStrip({super.key, this.compact = false});

  /// Réduit la hauteur pour les [AppBar] à titre sur deux lignes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scope = AppSyncStatusScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: scope.notifier!,
      builder: (context, _) {
        final service = scope.notifier!;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SiamoisConnectionModeChip(
              mode: service.mode,
              compact: compact,
            ),
            SizedBox(width: compact ? 2 : 4),
            SiamoisSyncQueueBadge(
              count: service.queueCount,
              isSyncing: service.isSyncing,
              compact: compact,
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.syncQueue);
              },
            ),
          ],
        );
      },
    );
  }
}
