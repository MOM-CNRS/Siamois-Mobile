import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// Ligne de liste professionnelle (projet, UE, document, mobilier…).
class SiamoisEntityTile extends StatelessWidget {
  const SiamoisEntityTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: SiamoisColors.surfaceCard,
      elevation: 0,
      borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: SiamoisColors.primaryContainer.withValues(alpha: 0.4),
        highlightColor: SiamoisColors.primaryContainer.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: SiamoisColors.borderSubtle),
            borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barre accent gauche
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SiamoisColors.primaryLight,
                        SiamoisColors.primary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(SiamoisSpacing.radiusLg),
                      bottomLeft: Radius.circular(SiamoisSpacing.radiusLg),
                    ),
                  ),
                ),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              if (subtitle != null &&
                                  subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: SiamoisColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                        if (showChevron && onTap != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: SiamoisColors.textTertiary,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar carré avec initiale ou icône, dégradé subtil.
class SiamoisEntityAvatar extends StatelessWidget {
  const SiamoisEntityAvatar({
    super.key,
    required this.label,
    this.icon,
    this.size = 44,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? SiamoisColors.primaryDark;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: backgroundColor != null
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SiamoisColors.primaryContainer,
                  Color(0xFFB8D4E2),
                ],
              ),
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.48, color: fg)
          : Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
    );
  }
}

/// Pastille de compteur (ex. nombre d'UE).
class SiamoisCountBadge extends StatelessWidget {
  const SiamoisCountBadge({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SiamoisColors.accentMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SiamoisColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SiamoisColors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: SiamoisColors.accent,
            ),
          ),
        ],
      ),
    );

    if (tooltip == null) return chip;
    return Tooltip(message: tooltip, child: chip);
  }
}
