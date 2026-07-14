/// Préfixe des identifiants projet créés hors ligne (`local:…`).
const kLocalProjectIdPrefix = 'local:';

/// Identifiants locaux pour les projets en attente de synchronisation.
abstract final class ProjectLocalId {
  static bool isLocalListId(String id) => id.startsWith(kLocalProjectIdPrefix);

  static String newLocalUuid() =>
      '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  static String toListId(String localUuid) =>
      '$kLocalProjectIdPrefix$localUuid';

  static String localIdFromListId(String listId) {
    if (!isLocalListId(listId)) return listId;
    return listId.substring(kLocalProjectIdPrefix.length);
  }
}
