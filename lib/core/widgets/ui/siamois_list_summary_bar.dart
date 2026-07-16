import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// Bandeau compteur compact, pleine largeur, au-dessus d’une liste.
class SiamoisListSummaryBar extends StatelessWidget {
  const SiamoisListSummaryBar({
    super.key,
    required this.count,
    required this.singularLabel,
    required this.pluralLabel,
    this.icon = Icons.list_alt_rounded,
    this.isSearching = false,
    this.searchQuery,
  });

  final int count;
  final String singularLabel;
  final String pluralLabel;
  final IconData icon;
  final bool isSearching;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = searchQuery?.trim();
    final showSearchContext =
        isSearching && query != null && query.isNotEmpty;

    final countLabel = showSearchContext
        ? (count > 1 ? 'résultats' : 'résultat')
        : (count > 1 ? pluralLabel : singularLabel);

    return Material(
      color: SiamoisColors.primaryContainer.withValues(alpha: 0.45),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: SiamoisColors.primary.withValues(alpha: 0.14),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SiamoisSpacing.pageHorizontal,
          vertical: SiamoisSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              showSearchContext ? Icons.search_rounded : icon,
              size: 16,
              color: SiamoisColors.primary,
            ),
            const SizedBox(width: SiamoisSpacing.xs),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SiamoisColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: ' $countLabel',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: SiamoisColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    if (showSearchContext) ...[
                      TextSpan(
                        text: ' · « $query »',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: SiamoisColors.textTertiary,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
