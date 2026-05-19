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
  });

  final int stepIndex;
  final int stepCount;
  final String stepLabel;
  final double progress;
  final List<String> logs;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  static const stepLabels = [
    'Authentification locale',
    'Vocabulaires',
    'Formulaires (projet, document, mobilier)',
    'Liste des projets',
    'Finalisation',
  ];
}
