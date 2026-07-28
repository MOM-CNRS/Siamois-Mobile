/// URL de base par défaut de l’API Siamois (prod).
///
/// Utilisée au premier lancement si aucune URL n’est enregistrée.
/// L’utilisateur peut la modifier dans Paramètres serveur
/// (`SharedPreferences`).
const String kSiamoisServerBaseUrl = 'https://siamois2.mom.fr/siamois2';

/// Alias d’exemple UI (même valeur que le défaut prod).
const String kSiamoisServerBaseUrlExample = kSiamoisServerBaseUrl;

/// Exemple pour un backend local (développement).
const String kSiamoisServerLocalUrlExample = 'http://localhost:8099/siamois';
