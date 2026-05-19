import '../../features/auth/auth_repository.dart';
import '../../features/projects/recording_units/recording_unit_detail_store.dart';
import '../database/app_database.dart';
import 'entity_snapshot_store.dart';
import 'outbox_store.dart';
import 'sync_action_models.dart';
import 'sync_conflict_exception.dart';

/// Rejoue la file `sync_actions` vers l’API.
class OutboxSyncEngine {
  OutboxSyncEngine({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<OutboxSyncResult> syncAll() async {
    final outbox = OutboxStore(_db);
    final pending = await outbox.pendingActions();
    if (pending.isEmpty) {
      return const OutboxSyncResult(synced: 0, failed: 0, conflicts: 0);
    }

    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    for (final action in pending) {
      await _db.updateSyncActionStatus(
        actionId: action.actionId,
        status: SyncActionStatus.uploading,
      );

      try {
        switch (action.entityType) {
          case SyncEntityType.recordingUnit:
            await _syncRecordingUnitUpdate(action);
            break;
          default:
            throw AuthException(
              'Type « ${action.entityType} » non pris en charge pour la sync.',
            );
        }
        await _db.deleteSyncAction(action.actionId);
        synced++;
      } on SyncConflictException catch (e) {
        await _db.updateSyncActionStatus(
          actionId: action.actionId,
          status: SyncActionStatus.conflict,
          errorMessage: e.toString(),
        );
        conflicts++;
      } on AuthException catch (e) {
        await _db.updateSyncActionStatus(
          actionId: action.actionId,
          status: SyncActionStatus.failed,
          errorMessage: e.message,
        );
        failed++;
      } catch (e) {
        await _db.updateSyncActionStatus(
          actionId: action.actionId,
          status: SyncActionStatus.failed,
          errorMessage: e.toString(),
        );
        failed++;
      }
    }

    return OutboxSyncResult(
      synced: synced,
      failed: failed,
      conflicts: conflicts,
    );
  }

  Future<void> _syncRecordingUnitUpdate(SyncActionEntry action) async {
    final ruId = action.serverEntityId?.trim();
    if (ruId == null || ruId.isEmpty) {
      throw AuthException('UE sans identifiant serveur.');
    }

    final fieldAnswersRaw = action.payload['fieldAnswers'];
    final fieldAnswers = fieldAnswersRaw is Map
        ? Map<String, dynamic>.from(fieldAnswersRaw)
        : <String, dynamic>{};

    final detail = await _auth.patchRecordingUnit(
      ruId,
      fieldAnswers: fieldAnswers,
      expectedRevision: action.baseServerRevision,
    );

    final store = RecordingUnitDetailStore(auth: _auth, db: _db);
    final projectId = action.payload['projectId']?.toString();
    await store.saveAfterMutation(
      detail,
      projectId: projectId,
    );

    final snapshotStore = EntitySnapshotStore(_db);
    await snapshotStore.saveRecordingUnitSnapshot(
      entityId: ruId,
      serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
      detailApiData: detail.toApiData(),
    );
  }
}

class OutboxSyncResult {
  const OutboxSyncResult({
    required this.synced,
    required this.failed,
    required this.conflicts,
  });

  final int synced;
  final int failed;
  final int conflicts;

  bool get hasWork => synced > 0 || failed > 0 || conflicts > 0;
}
