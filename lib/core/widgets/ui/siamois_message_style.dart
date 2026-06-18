import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';

/// Type sémantique d’un message utilisateur.
enum SiamoisMessageKind {
  info,
  error,
}

/// Couleurs et icône associées à un type de message.
class SiamoisMessageStyle {
  const SiamoisMessageStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData icon;

  static SiamoisMessageStyle forKind(SiamoisMessageKind kind) {
    return switch (kind) {
      SiamoisMessageKind.info => const SiamoisMessageStyle(
        backgroundColor: SiamoisColors.infoMuted,
        borderColor: SiamoisColors.infoBorder,
        foregroundColor: SiamoisColors.info,
        icon: Icons.info_outline_rounded,
      ),
      SiamoisMessageKind.error => SiamoisMessageStyle(
        backgroundColor: SiamoisColors.error.withValues(alpha: 0.08),
        borderColor: SiamoisColors.error.withValues(alpha: 0.28),
        foregroundColor: SiamoisColors.error,
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
