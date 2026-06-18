import 'package:flutter/material.dart';

import 'siamois_message_style.dart';
import 'siamois_spacing.dart';

/// Affichage cohérent des messages d’information et d’erreur (SnackBar).
abstract final class SiamoisMessenger {
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, SiamoisMessageKind.info, duration: duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, SiamoisMessageKind.error, duration: duration);
  }

  static SnackBar snackBar(
    String message,
    SiamoisMessageKind kind, {
    Duration? duration,
  }) {
    final style = SiamoisMessageStyle.forKind(kind);

    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: style.backgroundColor,
      duration: duration ?? const Duration(seconds: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
        side: BorderSide(color: style.borderColor),
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foregroundColor, size: 20),
          const SizedBox(width: SiamoisSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: style.foregroundColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _show(
    BuildContext context,
    String message,
    SiamoisMessageKind kind, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      snackBar(message, kind, duration: duration),
    );
  }
}

extension SiamoisMessengerContext on BuildContext {
  void showInfoMessage(String message, {Duration? duration}) {
    SiamoisMessenger.showInfo(this, message, duration: duration);
  }

  void showErrorMessage(String message, {Duration? duration}) {
    SiamoisMessenger.showError(this, message, duration: duration);
  }
}
