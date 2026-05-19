import 'dart:convert';

import '../database/app_database.dart';
import 'sync_action_models.dart';

/// Mémorise la révision serveur au chargement d’une entité.
class EntitySnapshotStore {
  EntitySnapshotStore(this._db);

  final AppDatabase _db;

  Future<void> saveRecordingUnitSnapshot({
    required String entityId,
    required int serverRevision,
    required Map<String, dynamic> detailApiData,
  }) {
    return _db.upsertEntitySyncSnapshot(
      entityType: SyncEntityType.recordingUnit,
      entityId: entityId,
      baseServerRevision: serverRevision,
      snapshotJson: jsonEncode(detailApiData),
    );
  }

  Future<int?> recordingUnitBaseRevision(String entityId) async {
    final row = await _db.entitySyncSnapshot(
      SyncEntityType.recordingUnit,
      entityId,
    );
    return row?.baseServerRevision;
  }

  Future<Map<String, dynamic>?> recordingUnitBaseSnapshot(
    String entityId,
  ) async {
    final row = await _db.entitySyncSnapshot(
      SyncEntityType.recordingUnit,
      entityId,
    );
    if (row == null) return null;
    final decoded = jsonDecode(row.snapshotJson);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }
}

/// Lit `syncRevision` depuis la ressource UE de l’API.
int readRecordingUnitSyncRevision(Map<String, dynamic> recordingUnitMap) {
  final raw = recordingUnitMap['syncRevision'] ?? recordingUnitMap['sync_revision'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
