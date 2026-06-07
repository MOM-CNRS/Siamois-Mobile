/// Préfixe des identifiants UE créés hors ligne (`local:…`).
const kLocalRecordingUnitIdPrefix = 'local:';

/// Identifiants locaux pour les UE en attente de synchronisation.
abstract final class RecordingUnitLocalId {
  static bool isLocalListId(String id) =>
      id.startsWith(kLocalRecordingUnitIdPrefix);

  static String newLocalUuid() =>
      '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  static String toListId(String localUuid) =>
      '$kLocalRecordingUnitIdPrefix$localUuid';

  static String localIdFromListId(String listId) {
    if (!isLocalListId(listId)) return listId;
    return listId.substring(kLocalRecordingUnitIdPrefix.length);
  }
}
