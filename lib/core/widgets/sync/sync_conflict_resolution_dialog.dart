import 'package:flutter/material.dart';

import '../../sync/sync_conflict_payload.dart';
import '../../theme/siamois_colors.dart';

/// Choix proposé lors d’un conflit de révision serveur.
enum SyncConflictResolution {
  cancel,
  useServer,
  retryLocal,
}

/// Dialogue de résolution d’un conflit offline / sync.
Future<SyncConflictResolution> showSyncConflictResolutionDialog({
  required BuildContext context,
  required String entityLabel,
  SyncConflictPayload? payload,
  bool showRetryLocal = true,
}) {
  final revisionLine = payload != null &&
          (payload.expectedRevision > 0 || payload.currentRevision > 0)
      ? '\nRévision locale ${payload.expectedRevision} → '
          'serveur ${payload.currentRevision}.'
      : '';

  return showDialog<SyncConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.sync_problem_rounded, color: SiamoisColors.warning),
      title: const Text('Conflit de synchronisation'),
      content: SingleChildScrollView(
        child: Text(
          '« $entityLabel » a été modifié sur le serveur pendant votre '
          'travail hors ligne.$revisionLine\n\n'
          'Choisissez comment résoudre le conflit :',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, SyncConflictResolution.cancel),
          child: const Text('Annuler'),
        ),
        if (showRetryLocal)
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, SyncConflictResolution.retryLocal),
            child: const Text('Réappliquer mes modifications'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, SyncConflictResolution.useServer),
          child: const Text('Version serveur'),
        ),
      ],
    ),
  ).then((value) => value ?? SyncConflictResolution.cancel);
}
