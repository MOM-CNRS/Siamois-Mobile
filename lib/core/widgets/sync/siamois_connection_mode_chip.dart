import 'package:flutter/material.dart';

import '../../sync/app_sync_status_service.dart';
import '../../theme/siamois_colors.dart';

/// Bandeau compact : Connecté (vert) / Hors connexion (orange).
class SiamoisConnectionModeChip extends StatelessWidget {
  const SiamoisConnectionModeChip({
    super.key,
    required this.mode,
    this.compact = false,
  });

  final AppConnectionMode mode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final connected = mode == AppConnectionMode.connected;
    final bg = connected
        ? SiamoisColors.success.withValues(alpha: 0.12)
        : SiamoisColors.warning.withValues(alpha: 0.14);
    final fg = connected ? SiamoisColors.success : SiamoisColors.warning;
    final label = connected ? 'Connecté' : 'Hors connexion';
    final icon =
        connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: fg),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: (compact
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
