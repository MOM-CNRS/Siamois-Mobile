/// Arguments de navigation vers l’écran de synchronisation.
class SyncRouteArgs {
  const SyncRouteArgs({
    required this.cameFromOnlineLogin,
    this.manual = false,
    this.queueOnly = false,
    this.cacheOnly = false,
  });

  final bool cameFromOnlineLogin;
  final bool manual;

  /// Sync manuelle : envoi de la file d’attente uniquement (sans rechargement global).
  final bool queueOnly;

  /// Rechargement du cache depuis le serveur (sans envoi de la file d’attente).
  final bool cacheOnly;
}
