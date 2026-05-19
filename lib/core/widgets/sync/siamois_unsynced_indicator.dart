import 'package:flutter/material.dart';

import '../../sync/entity_sync_state.dart';
import '../../theme/siamois_colors.dart';

/// Pastille « non synchronisé » sur une carte entité.
class SiamoisUnsyncedIndicator extends StatelessWidget {
  const SiamoisUnsyncedIndicator({
    super.key,
    required this.state,
  });

  final EntitySyncState state;

  @override
  Widget build(BuildContext context) {
    if (!state.needsSyncIndicator) return const SizedBox.shrink();

    final isError = state == EntitySyncState.error;
    final color = isError ? SiamoisColors.error : SiamoisColors.warning;
    final icon =
        isError ? Icons.error_outline_rounded : Icons.cloud_upload_rounded;
    final tooltip = isError
        ? 'Synchronisation en erreur'
        : 'En attente de synchronisation';

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
