/// Préfixe des identifiants mobilier créés hors ligne (`local:…`).
const kLocalMobilierIdPrefix = 'local:';

/// Identifiants locaux pour les mobiliers en attente de synchronisation.
abstract final class MobilierLocalId {
  static bool isLocalListId(String id) => id.startsWith(kLocalMobilierIdPrefix);

  static String newLocalUuid() =>
      '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  static String toListId(String localUuid) =>
      '$kLocalMobilierIdPrefix$localUuid';
}
