import 'package:flutter/material.dart';

import '../../sync/sync_conflict_field_diff.dart';
import '../../theme/siamois_colors.dart';
import '../ui/siamois_spacing.dart';

/// Liste des champs avec code couleur selon le type d’écart.
class SyncConflictFieldsList extends StatelessWidget {
  const SyncConflictFieldsList({
    super.key,
    required this.diffs,
    this.compact = false,
  });

  final List<SyncConflictFieldDiff> diffs;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            'Comparaison des champs',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seuls les champs modifiés des deux côtés sont en conflit. '
            'Vos autres modifications sont simplement en attente d’envoi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: SiamoisColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: SiamoisSpacing.sm),
        ],
        _ConflictLegend(compact: compact),
        SizedBox(height: compact ? 8 : SiamoisSpacing.sm),
        for (final diff in diffs) ...[
          _ConflictFieldCard(diff: diff, compact: compact),
          if (diff != diffs.last) SizedBox(height: compact ? 8 : SiamoisSpacing.sm),
        ],
      ],
    );
  }
}

class _ConflictLegend extends StatelessWidget {
  const _ConflictLegend({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 8 : 12,
      runSpacing: 4,
      children: const [
        _LegendChip(color: SiamoisColors.error, label: 'Conflit'),
        _LegendChip(color: SiamoisColors.warning, label: 'Serveur seul.'),
        _LegendChip(color: SiamoisColors.primary, label: 'Vos modifs'),
        _LegendChip(color: SiamoisColors.success, label: 'Identique'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: SiamoisColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ConflictFieldCard extends StatelessWidget {
  const _ConflictFieldCard({
    required this.diff,
    required this.compact,
  });

  final SyncConflictFieldDiff diff;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentForKind(diff.kind);
    final icon = _iconForKind(diff.kind);

    return Container(
      padding: EdgeInsets.all(compact ? SiamoisSpacing.sm : SiamoisSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 16 : 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  diff.fieldLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            diff.kindLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: SiamoisColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 6 : SiamoisSpacing.sm),
          _ValueRow(
            icon: Icons.phone_android_rounded,
            label: diff.kind == SyncFieldConflictKind.serverOnly
                ? 'Dernière version connue'
                : 'Sur votre appareil',
            value: diff.localValue,
          ),
          const SizedBox(height: 6),
          _ValueRow(
            icon: Icons.cloud_outlined,
            label: 'Sur le serveur',
            value: diff.serverValue,
          ),
        ],
      ),
    );
  }

  static Color _accentForKind(SyncFieldConflictKind kind) {
    return switch (kind) {
      SyncFieldConflictKind.trueConflict => SiamoisColors.error,
      SyncFieldConflictKind.serverOnly => SiamoisColors.warning,
      SyncFieldConflictKind.localOnly => SiamoisColors.primary,
      SyncFieldConflictKind.aligned => SiamoisColors.success,
    };
  }

  static IconData _iconForKind(SyncFieldConflictKind kind) {
    return switch (kind) {
      SyncFieldConflictKind.trueConflict => Icons.warning_amber_rounded,
      SyncFieldConflictKind.serverOnly => Icons.cloud_sync_rounded,
      SyncFieldConflictKind.localOnly => Icons.edit_outlined,
      SyncFieldConflictKind.aligned => Icons.check_circle_outline_rounded,
    };
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: SiamoisColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: SiamoisColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
