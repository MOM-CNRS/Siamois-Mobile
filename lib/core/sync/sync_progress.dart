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
    this.currentActionLabel,
    this.totalActions = 0,
    this.completedActions = 0,
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

  /// Libellé de l’action ou de l’étape en cours.
  final String? currentActionLabel;

  /// Nombre total d’étapes / actions à traiter.
  final int totalActions;

  /// Actions déjà traitées (succès ou échec).
  final int completedActions;

  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  /// Actions outbox / documents en échec après la sync.
  final int failedActionCount;

  /// Actions outbox en conflit après la sync.
  final int conflictCount;

  int get remainingActions {
    if (totalActions <= 0) return 0;
    return (totalActions - completedActions).clamp(0, totalActions);
  }

  /// Étapes de préparation avant l’envoi de la file d’attente.
  static const bootstrapStepCount = 4;

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
    'Vocabulaires et lieux',
    'Formulaires (projet, document, mobilier)',
    'Liste des projets',
    'Finalisation',
  ];
}
