import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' hide Form;
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/ui/siamois_messenger.dart';

/// Demande confirmation avant de vider le cache hors ligne.
Future<bool> confirmClearCache(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: const Icon(
          Icons.delete_sweep_rounded,
          color: SiamoisColors.warning,
        ),
        title: const Text('Vider le cache ?'),
        content: const Text(
          'Les projets, unités d’enregistrement, documents, formulaires, '
          'vocabulaires et la file de synchronisation en attente seront '
          'supprimés de cet appareil.\n\n'
          'Votre session de connexion est conservée. Relancez une '
          'synchronisation pour retélécharger les données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: SiamoisColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vider le cache'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Supprime les données locales mises en cache (sans déconnexion).
Future<void> clearApplicationCache({
  required BuildContext context,
  required AppDatabase database,
}) async {
  if (!await confirmClearCache(context)) return;
  if (!context.mounted) return;

  final service = AppSyncStatusScope.maybeOf(context)?.notifier;
  if (service?.isSyncing == true) {
    context.showInfoMessage(
      'Attendez la fin de la synchronisation en cours.',
    );
    return;
  }

  try {
    await database.clearOfflineCache();
    await service?.resetAfterCacheClear();
    if (!context.mounted) return;
    context.showInfoMessage('Cache local vidé.');
  } catch (e) {
    if (!context.mounted) return;
    context.showErrorMessage('Impossible de vider le cache : $e');
  }
}
