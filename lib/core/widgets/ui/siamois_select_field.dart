import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import 'siamois_spacing.dart';

/// Styles partagés pour listes déroulantes, autocomplétions et sélections multiples.
abstract final class SiamoisFieldDecoration {
  static InputDecoration forField({
    required String label,
    String? hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: hint,
      helperMaxLines: 3,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      errorText: errorText,
    );
  }

  static Widget loadingSuffix() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget? clearSuffix({
    required bool visible,
    required VoidCallback onClear,
  }) {
    if (!visible) return null;
    return IconButton(
      tooltip: 'Effacer',
      onPressed: onClear,
      icon: const Icon(Icons.close_rounded, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: SiamoisColors.textSecondary,
      ),
    );
  }

  static Widget searchSuffix({bool loading = false}) {
    if (loading) return loadingSuffix();
    return const Icon(
      Icons.search_rounded,
      color: SiamoisColors.textTertiary,
    );
  }

  static Widget personSearchSuffix({bool loading = false}) {
    if (loading) return loadingSuffix();
    return const Icon(
      Icons.person_search_rounded,
      color: SiamoisColors.textTertiary,
    );
  }
}

/// En-tête label + aide pour les sélecteurs composites.
class SiamoisSelectFieldLabel extends StatelessWidget {
  const SiamoisSelectFieldLabel({
    super.key,
    required this.label,
    this.hint,
    this.trailing,
  });

  final String label;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SiamoisColors.textPrimary,
                ),
              ),
              if (hint != null && hint!.trim().isNotEmpty) ...[
                const SizedBox(height: SiamoisSpacing.xxs),
                Text(
                  hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SiamoisColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Liste déroulante (vocabulaire / concept).
class SiamoisSelectDropdown<T> extends StatelessWidget {
  const SiamoisSelectDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hintText,
  });

  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: SiamoisColors.textSecondary,
      ),
      borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
      dropdownColor: SiamoisColors.surfaceCard,
      elevation: 8,
      menuMaxHeight: 360,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: SiamoisColors.textPrimary,
      ),
      hint: hintText != null
          ? Text(
              hintText!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: SiamoisColors.textTertiary,
              ),
            )
          : null,
      decoration: SiamoisFieldDecoration.forField(
        label: label,
        hint: hint,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Panneau de suggestions (autocomplétion).
class SiamoisSelectSuggestionsPanel extends StatelessWidget {
  const SiamoisSelectSuggestionsPanel({
    super.key,
    required this.children,
    this.header,
    this.emptyMessage,
    this.maxHeight = 280,
  });

  final List<Widget> children;
  final String? header;
  final String? emptyMessage;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      if (emptyMessage == null) return const SizedBox.shrink();
      return _SelectPanelShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SiamoisSpacing.md,
            vertical: SiamoisSpacing.sm,
          ),
          child: Text(
            emptyMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SiamoisColors.textTertiary,
                ),
          ),
        ),
      );
    }

    return _SelectPanelShell(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SiamoisSpacing.md,
                  SiamoisSpacing.sm,
                  SiamoisSpacing.md,
                  SiamoisSpacing.xxs,
                ),
                child: Text(
                  header!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SiamoisColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: SiamoisSpacing.xs),
                itemCount: children.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: SiamoisSpacing.md,
                  endIndent: SiamoisSpacing.md,
                  color: SiamoisColors.borderSubtle,
                ),
                itemBuilder: (_, index) => children[index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SiamoisSelectSuggestionTile extends StatelessWidget {
  const SiamoisSelectSuggestionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? SiamoisColors.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SiamoisSpacing.md,
            vertical: SiamoisSpacing.sm,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: SiamoisSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: SiamoisColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: SiamoisSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Valeur sélectionnée (chip).
class SiamoisSelectChip extends StatelessWidget {
  const SiamoisSelectChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: SiamoisColors.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusSm),
        side: const BorderSide(color: SiamoisColors.border),
      ),
      child: InkWell(
        onTap: onDeleted,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusSm),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SiamoisSpacing.sm,
            subtitle == null ? 8 : 6,
            onDeleted != null ? 4 : SiamoisSpacing.sm,
            subtitle == null ? 8 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: SiamoisColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDeleted != null)
                IconButton(
                  onPressed: onDeleted,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: SiamoisColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne à case à cocher dans un panneau de sélection multiple.
class SiamoisSelectCheckboxRow extends StatelessWidget {
  const SiamoisSelectCheckboxRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: value
          ? SiamoisColors.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SiamoisSpacing.xs,
            vertical: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              value ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SiamoisColors.textSecondary,
                          ),
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
    );
  }
}

class _SelectPanelShell extends StatelessWidget {
  const _SelectPanelShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: SiamoisSpacing.xs),
      decoration: BoxDecoration(
        color: SiamoisColors.surfaceCard,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
        border: Border.all(color: SiamoisColors.border),
        boxShadow: [
          BoxShadow(
            color: SiamoisColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
