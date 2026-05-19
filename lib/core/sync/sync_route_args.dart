/// Arguments de navigation vers l’écran de synchronisation.
class SyncRouteArgs {
  const SyncRouteArgs({
    required this.cameFromOnlineLogin,
    this.manual = false,
  });

  final bool cameFromOnlineLogin;
  final bool manual;
}
