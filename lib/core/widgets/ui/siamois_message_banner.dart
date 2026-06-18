import 'package:flutter/material.dart';

export 'siamois_message_style.dart';
import 'siamois_message_style.dart';
import 'siamois_spacing.dart';

/// Bandeau inline pour un message d’information ou d’erreur.
class SiamoisMessageBanner extends StatelessWidget {
  const SiamoisMessageBanner({
    super.key,
    required this.message,
    required this.kind,
    this.textAlign = TextAlign.start,
  });

  final String message;
  final SiamoisMessageKind kind;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = SiamoisMessageStyle.forKind(kind);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiamoisSpacing.md),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foregroundColor, size: 20),
          const SizedBox(width: SiamoisSpacing.sm),
          Expanded(
            child: Text(
              message,
              textAlign: textAlign,
              style: theme.textTheme.bodySmall?.copyWith(
                color: style.foregroundColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
