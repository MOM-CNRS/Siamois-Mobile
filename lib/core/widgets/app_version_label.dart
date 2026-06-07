import 'package:flutter/material.dart';

import '../config/app_version.dart';
import '../theme/siamois_colors.dart';

/// Libellé de version discret (`v1.0.0`).
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({
    super.key,
    this.textAlign = TextAlign.center,
  });

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final label = AppVersion.label;
    if (label.isEmpty) return const SizedBox.shrink();

    return Text(
      label,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SiamoisColors.textTertiary,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
    );
  }
}
