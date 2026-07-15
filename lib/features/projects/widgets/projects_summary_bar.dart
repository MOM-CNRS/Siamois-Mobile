import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';

/// Bandeau compteur au-dessus de la liste des projets.
class ProjectsSummaryBar extends StatelessWidget {
  const ProjectsSummaryBar({
    super.key,
    required this.projectCount,
    required this.recordingUnitCount,
    this.isSearching = false,
    this.searchQuery,
  });

  final int projectCount;
  final int recordingUnitCount;
  final bool isSearching;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = searchQuery?.trim();
    final showSearchContext =
        isSearching && query != null && query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.sm,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSearchContext) ...[
            Text(
              'Résultats pour « $query »',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: SiamoisColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SiamoisSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: showSearchContext
                      ? Icons.search_rounded
                      : Icons.folder_outlined,
                  value: projectCount,
                  label: showSearchContext
                      ? (projectCount > 1 ? 'résultats' : 'résultat')
                      : (projectCount > 1 ? 'projets' : 'projet'),
                  tone: _MetricTone.primary,
                ),
              ),
              const SizedBox(width: SiamoisSpacing.xs),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.layers_outlined,
                  value: recordingUnitCount,
                  label: 'UE',
                  tone: _MetricTone.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MetricTone { primary, accent }

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final int value;
  final String label;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = tone == _MetricTone.primary;
    final accent = isPrimary ? SiamoisColors.primary : SiamoisColors.accent;
    final fill = isPrimary
        ? SiamoisColors.primaryContainer.withValues(alpha: 0.55)
        : SiamoisColors.accentMuted;
    final border = accent.withValues(alpha: isPrimary ? 0.22 : 0.28);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SiamoisSpacing.md,
        vertical: SiamoisSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SiamoisColors.surfaceCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: SiamoisSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: SiamoisColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: SiamoisColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
