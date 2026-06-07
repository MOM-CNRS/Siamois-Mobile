/// Résultat renvoyé à la fermeture de l’écran de synchronisation manuelle.
enum SyncRunResult {
  success,
  conflicts,
  failures,
}

/// Issue finale d’une synchronisation terminée (hors échec de bootstrap).
enum SyncCompletionOutcome {
  success,
  hasConflicts,
  hasFailures,
}

/// État affiché par l’écran de synchronisation.
class SyncProgress {
  const SyncProgress({
    required this.stepIndex,
    required this.stepCount,
    required this.stepLabel,
    required this.progress,
    required this.logs,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.failedActionCount = 0,
    this.conflictCount = 0,
  });

  final int stepIndex;
  final int stepCount;
  final String stepLabel;
  final double progress;
  final List<String> logs;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  /// Actions outbox / documents en échec après la sync.
  final int failedActionCount;

  /// Actions outbox en conflit après la sync.
  final int conflictCount;

  /// Échec bloquant du bootstrap (avant fin du pipeline).
  bool get isBootstrapError => hasError && !isComplete;

  /// Résultat une fois le pipeline terminé.
  SyncCompletionOutcome? get completionOutcome {
    if (!isComplete) return null;
    if (failedActionCount > 0) return SyncCompletionOutcome.hasFailures;
    if (conflictCount > 0) return SyncCompletionOutcome.hasConflicts;
    return SyncCompletionOutcome.success;
  }

  SyncRunResult? get runResult => switch (completionOutcome) {
        SyncCompletionOutcome.success => SyncRunResult.success,
        SyncCompletionOutcome.hasConflicts => SyncRunResult.conflicts,
        SyncCompletionOutcome.hasFailures => SyncRunResult.failures,
        null => null,
      };

  static const stepLabels = [
    'Authentification locale',
    'Vocabulaires',
    'Formulaires (projet, document, mobilier)',
    'Liste des projets',
    'Finalisation',
  ];
}
