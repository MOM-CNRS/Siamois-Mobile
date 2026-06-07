import '../../features/auth/auth_repository.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
import '../../features/projects/recording_units/recording_unit_detail_store.dart';
import '../../features/projects/recording_units/recording_unit_list_store.dart';
import '../../features/projects/project_detail_models.dart';
import 'entity_snapshot_store.dart';
import 'sync_action_models.dart';
import 'sync_conflict_payload.dart';
import '../database/app_database.dart';

/// Applique la résolution choisie pour une action outbox en conflit.
class SyncConflictResolver {
  SyncConflictResolver({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// Remplace le cache local par la version serveur et retire l’action.
  Future<void> acceptServerVersion(SyncActionEntry action) async {
    if (action.entityType == SyncEntityType.recordingUnit &&
        action.operation == SyncOperation.update) {
      await _acceptRecordingUnitServerVersion(action);
      return;
    }
    throw AuthException(
      'Résolution « version serveur » non prise en charge pour '
      '« ${action.entityType} ».',
    );
  }

  /// Repart de la révision serveur actuelle et réessaie d’envoyer les changements locaux.
  Future<void> retryLocalChanges(SyncActionEntry action) async {
    final payload = SyncConflictPayload.tryParse(action.errorMessage);
    if (payload == null || payload.currentRevision <= 0) {
      throw AuthException(
        'Impossible de réappliquer : détails du conflit indisponibles.',
      );
    }

    if (action.entityType == SyncEntityType.recordingUnit &&
        action.operation == SyncOperation.update) {
      final entityId = action.serverEntityId?.trim();
      if (entityId != null &&
          entityId.isNotEmpty &&
          payload.serverState != null) {
        await EntitySnapshotStore(_db).saveRecordingUnitSnapshot(
          entityId: entityId,
          serverRevision: payload.currentRevision,
          detailApiData: payload.serverState!,
        );
      }
    }

    await _db.requeueSyncActionAfterRebase(
      actionId: action.actionId,
      baseServerRevision: payload.currentRevision,
    );
  }

  Future<void> _acceptRecordingUnitServerVersion(SyncActionEntry action) async {
    final ruId = action.serverEntityId?.trim();
    if (ruId == null || ruId.isEmpty) {
      throw AuthException('Identifiant UE introuvable pour la résolution.');
    }

    final payload = SyncConflictPayload.tryParse(action.errorMessage);
    RecordingUnitMobileDetail detail;
    if (payload?.serverState != null) {
      detail = RecordingUnitMobileDetail.fromApiData(payload!.serverState!);
    } else {
      detail = await _auth.fetchRecordingUnitDetail(ruId);
    }

    final projectId = action.payload['projectId']?.toString();
    final store = RecordingUnitDetailStore(auth: _auth, db: _db);
    await store.saveAfterMutation(detail, projectId: projectId);

    await EntitySnapshotStore(_db).saveRecordingUnitSnapshot(
      entityId: ruId,
      serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
      detailApiData: detail.toApiData(),
    );

    final item = RecordingUnitItem.fromJson(detail.recordingUnit);
    if (item.id.isNotEmpty && projectId != null && projectId.trim().isNotEmpty) {
      await RecordingUnitListStore(auth: _auth, db: _db).upsertLocal(
        item: item,
        projectId: projectId.trim(),
        typeConceptId: detail.typeConceptId,
      );
    }

    await _db.deleteSyncAction(action.actionId);
  }
}
