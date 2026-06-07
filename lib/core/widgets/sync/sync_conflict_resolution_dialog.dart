import 'package:flutter/material.dart';

import '../../sync/sync_conflict_field_diff.dart';
import '../../sync/sync_conflict_payload.dart';
import '../../theme/siamois_colors.dart';
import '../ui/siamois_spacing.dart';
import 'sync_conflict_fields_list.dart';

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
  List<SyncConflictFieldDiff> fieldDiffs = const [],
  bool showRetryLocal = true,
}) {
  return showDialog<SyncConflictResolution>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.sync_problem_rounded, color: SiamoisColors.warning),
      title: const Text('Conflit de synchronisation'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '« $entityLabel » a été modifié sur le serveur pendant votre '
              'travail hors ligne.',
            ),
            if (fieldDiffs.isNotEmpty) ...[
              const SizedBox(height: SiamoisSpacing.md),
              SyncConflictFieldsList(diffs: fieldDiffs, compact: true),
            ],
            const SizedBox(height: SiamoisSpacing.md),
            const Text('Choisissez comment résoudre le conflit :'),
          ],
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
