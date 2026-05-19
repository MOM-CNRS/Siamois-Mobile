import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';

/// Icône de file d’attente avec badge (pending + erreurs).
class SiamoisSyncQueueBadge extends StatelessWidget {
  const SiamoisSyncQueueBadge({
    super.key,
    required this.count,
    this.isSyncing = false,
    this.compact = false,
    this.onPressed,
  });

  final int count;
  final bool isSyncing;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBadge = count > 0;

    final iconSize = compact ? 20.0 : 22.0;

    return IconButton(
      tooltip: showBadge
          ? '$count opération${count > 1 ? 's' : ''} en attente ou en erreur'
          : 'Aucune opération en attente',
      onPressed: onPressed,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      constraints: compact
          ? const BoxConstraints(minWidth: 36, minHeight: 36)
          : null,
      padding: compact ? const EdgeInsets.all(6) : null,
      iconSize: iconSize,
      icon: Badge(
        isLabelVisible: showBadge,
        label: Text('$count'),
        backgroundColor: SiamoisColors.error,
        child: isSyncing
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(
                Icons.sync_rounded,
                size: iconSize,
                color: showBadge
                    ? SiamoisColors.warning
                    : SiamoisColors.textSecondary,
              ),
      ),
    );
  }
}
