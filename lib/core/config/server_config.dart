/// URL de base par défaut de l’API Siamois (API mobile JWT / CRUD).
///
/// Utilisée au premier lancement si aucune URL n’est enregistrée.
/// L’utilisateur peut la modifier dans Paramètres serveur
/// (`SharedPreferences`).
///
/// Ne pas utiliser `https://siamois.mom.fr/siamois` : ancienne API lecture
/// seule, sans `POST /api/v1/auth/login` ni formulaires mobile.
const String kSiamoisServerBaseUrl = 'https://siamois2.mom.fr/siamois2';

/// Alias d’exemple UI (même valeur que le défaut prod).
const String kSiamoisServerBaseUrlExample = kSiamoisServerBaseUrl;

/// Exemple pour un backend local (développement).
const String kSiamoisServerLocalUrlExample = 'http://localhost:8099/siamois';

/// Ancienne API publique lecture seule (incompatible avec l’app mobile).
const String kSiamoisLegacyReadOnlyServerUrl = 'https://siamois.mom.fr/siamois';
