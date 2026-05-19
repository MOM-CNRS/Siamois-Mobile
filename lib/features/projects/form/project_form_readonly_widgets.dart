import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
/// Champ formulaire en lecture seule (détail projet).
class ProjectFormReadOnlyField extends StatelessWidget {
  const ProjectFormReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.multiline = false,
  });

  final String label;
  final String? value;
  final String? hint;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = (value ?? '').trim().isEmpty ? '—' : value!.trim();
    final isEmpty = display == '—';

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        filled: true,
        fillColor: SiamoisColors.surfaceMuted.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      ),
      child: Text(
        display,
        maxLines: multiline ? null : 3,
        overflow: multiline ? null : TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isEmpty ? SiamoisColors.textTertiary : SiamoisColors.textPrimary,
          fontStyle: isEmpty ? FontStyle.italic : null,
          height: multiline ? 1.4 : 1.35,
        ),
      ),
    );
  }
}
