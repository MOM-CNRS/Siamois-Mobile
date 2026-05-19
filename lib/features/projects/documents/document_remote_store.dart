/// Accès URL serveur pour visualisation de documents (projet ou UE).
abstract class DocumentRemoteStore {
  bool get canOpenRemote;
  String? absoluteUrlFor(String? relativeUrl);
}
