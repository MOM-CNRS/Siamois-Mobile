import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../form/recording_unit_option.dart';

/// Panneau hiérarchie UE (parents / enfants) en fin de fiche détail.
class RecordingUnitHierarchyPanel extends StatelessWidget {
  const RecordingUnitHierarchyPanel({
    super.key,
    required this.parents,
    required this.children,
    required this.onOpenUnit,
    this.onAddParent,
    this.onAddChild,
    this.onRemoveParent,
    this.onRemoveChild,
    this.linking = false,
    this.offline = false,
  });

  final List<RecordingUnitOption> parents;
  final List<RecordingUnitOption> children;
  final void Function(RecordingUnitOption option) onOpenUnit;
  final VoidCallback? onAddParent;
  final VoidCallback? onAddChild;
  final void Function(RecordingUnitOption option)? onRemoveParent;
  final void Function(RecordingUnitOption option)? onRemoveChild;
  final bool linking;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uniqueParents = RecordingUnitOption.sortAscending(parents);
    final uniqueChildren = RecordingUnitOption.sortAscending(children);

    return Container(
      decoration: BoxDecoration(
        color: SiamoisColors.surfaceCard,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusXl),
        border: Border.all(color: SiamoisColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: SiamoisColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  SiamoisColors.primaryContainer.withValues(alpha: 0.55),
                  SiamoisColors.accentMuted.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SiamoisColors.surfaceCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    size: 20,
                    color: SiamoisColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unités liées',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: SiamoisColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${uniqueParents.length} parente(s) · '
                        '${uniqueChildren.length} fille(s)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (linking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (offline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: SiamoisColors.warning.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: SiamoisColors.warning.withValues(alpha: 0.3),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hors ligne — les liens ajoutés ou retirés seront '
                      'synchronisés au retour de la connexion.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SiamoisColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _HierarchyGroup(
            title: 'UE parentes',
            icon: Icons.north_east_rounded,
            accent: SiamoisColors.primary,
            options: uniqueParents,
            onOpen: onOpenUnit,
            onAdd: onAddParent,
            onRemove: onRemoveParent,
            addLabel: 'Ajouter une UE parente',
          ),
          Divider(
            height: 1,
            color: SiamoisColors.borderSubtle.withValues(alpha: 0.9),
          ),
          _HierarchyGroup(
            title: 'UE filles',
            icon: Icons.south_west_rounded,
            accent: SiamoisColors.accent,
            options: uniqueChildren,
            onOpen: onOpenUnit,
            onAdd: onAddChild,
            onRemove: onRemoveChild,
            addLabel: 'Ajouter une UE fille',
          ),
        ],
      ),
    );
  }
}

class _HierarchyGroup extends StatelessWidget {
  const _HierarchyGroup({
    required this.title,
    required this.icon,
    required this.accent,
    required this.options,
    required this.onOpen,
    this.onAdd,
    this.onRemove,
    required this.addLabel,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<RecordingUnitOption> options;
  final void Function(RecordingUnitOption option) onOpen;
  final VoidCallback? onAdd;
  final void Function(RecordingUnitOption option)? onRemove;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SiamoisColors.textPrimary,
                  ),
                ),
              ),
              _CountBadge(count: options.length, accent: accent),
            ],
          ),
          const SizedBox(height: 10),
          if (options.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: SiamoisColors.surfaceMuted.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
                border: Border.all(
                  color: SiamoisColors.borderSubtle,
                ),
              ),
              child: Text(
                'Aucune UE liée.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SiamoisColors.textSecondary,
                ),
              ),
            )
          else
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HierarchyUnitRow(
                  option: option,
                  accent: accent,
                  onTap: () => onOpen(option),
                  onRemove: onRemove == null
                      ? null
                      : () => onRemove!(option),
                ),
              ),
            ),
          if (onAdd != null) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: Text(addLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.accent,
  });

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
      ),
    );
  }
}

class _HierarchyUnitRow extends StatelessWidget {
  const _HierarchyUnitRow({
    required this.option,
    required this.accent,
    required this.onTap,
    this.onRemove,
  });

  final RecordingUnitOption option;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: SiamoisColors.surface,
      borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: SiamoisColors.borderSubtle),
            borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SiamoisColors.textPrimary,
                      ),
                    ),
                    if (option.typeLabel != null &&
                        option.typeLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.typeLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Retirer le lien',
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.link_off_rounded,
                    size: 20,
                    color: SiamoisColors.error.withValues(alpha: 0.85),
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SiamoisColors.textTertiary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
