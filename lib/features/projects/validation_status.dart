/// Statut de validation d’une entité (`validationStatus` côté API).
enum ValidationStatus {
  incomplete('INCOMPLETE', 'En cours'),
  complete('COMPLETE', 'Terminé'),
  validated('VALIDATED', 'Validé'),
  cancelled('CANCELLED', 'Annulé');

  const ValidationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// `null` si absent ou inconnu (valeur ajoutée côté serveur).
  static ValidationStatus? fromApi(Object? raw) {
    final value = raw?.toString().trim().toUpperCase();
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  /// Libellé à afficher dans une liste : rien pour l’état par défaut.
  static String? listLabel(ValidationStatus? status) =>
      status == null || status == incomplete ? null : status.label;
}
