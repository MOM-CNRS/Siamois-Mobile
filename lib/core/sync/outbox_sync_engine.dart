import '../../features/auth/auth_repository.dart';
import '../../features/projects/project_detail_models.dart';
import '../../features/projects/recording_units/recording_unit_detail_store.dart';
import '../../features/projects/mobiliers/mobilier_list_store.dart';
import '../../features/projects/mobiliers/mobilier_local_id.dart';
import '../../features/projects/recording_units/recording_unit_list_store.dart';
import '../../features/projects/recording_units/recording_unit_local_id.dart';
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
    await _db.resetSyncActionsForRetry();
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
            if (action.operation == SyncOperation.create) {
              await _syncRecordingUnitCreate(action);
            } else if (action.operation == SyncOperation.update) {
              await _syncRecordingUnitUpdate(action);
            } else {
              throw AuthException(
                'Opération « ${action.operation} » non prise en charge pour les UE.',
              );
            }
            break;
          case SyncEntityType.mobilier:
            if (action.operation == SyncOperation.create) {
              await _syncMobilierCreate(action);
            } else {
              throw AuthException(
                'Opération « ${action.operation} » non prise en charge pour les mobiliers.',
              );
            }
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
          errorMessage: e.encodeForStorage(),
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

  Future<void> _syncRecordingUnitCreate(SyncActionEntry action) async {
    final localId = action.localEntityId?.trim();
    final actionUnitId = action.payload['actionUnitId']?.toString().trim() ?? '';
    final typeRaw = action.payload['recordingUnitTypeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');

    if (actionUnitId.isEmpty || typeId == null) {
      throw AuthException('Création UE : données incomplètes dans la file d’attente.');
    }

    final fieldAnswersRaw = action.payload['fieldAnswers'];
    final fieldAnswers = fieldAnswersRaw is Map
        ? Map<String, dynamic>.from(fieldAnswersRaw)
        : <String, dynamic>{};

    final detail = await _auth.createRecordingUnit(
      actionUnitId: actionUnitId,
      recordingUnitTypeConceptId: typeId,
      fieldAnswers: fieldAnswers,
    );

    final serverId = RecordingUnitDetailStore.recordingUnitIdFromDetail(detail);
    final projectId = action.payload['projectId']?.toString();

    if (localId != null &&
        localId.isNotEmpty &&
        RecordingUnitLocalId.isLocalListId(localId)) {
      await _db.remapRecordingUnitResourceId(
        fromResourceId: localId,
        toResourceId: serverId,
      );
    }

    final store = RecordingUnitDetailStore(auth: _auth, db: _db);
    await store.saveAfterMutation(
      detail,
      projectId: projectId,
    );

    final item = RecordingUnitItem.fromJson(detail.recordingUnit);
    if (item.id.isNotEmpty && projectId != null && projectId.trim().isNotEmpty) {
      await RecordingUnitListStore(auth: _auth, db: _db).upsertLocal(
        item: item,
        projectId: projectId.trim(),
        typeConceptId: detail.typeConceptId,
      );
    }

    final snapshotStore = EntitySnapshotStore(_db);
    await snapshotStore.saveRecordingUnitSnapshot(
      entityId: serverId,
      serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
      detailApiData: detail.toApiData(),
    );
  }

  Future<void> _syncMobilierCreate(SyncActionEntry action) async {
    final localId = action.localEntityId?.trim();
    var recordingUnitId =
        action.payload['recordingUnitId']?.toString().trim() ?? '';
    final typeRaw = action.payload['specimenTypeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');

    if (recordingUnitId.isEmpty || typeId == null) {
      throw AuthException(
        'Création mobilier : données incomplètes dans la file d’attente.',
      );
    }

    if (RecordingUnitLocalId.isLocalListId(recordingUnitId)) {
      throw AuthException(
        'Synchronisez d’abord l’unité d’enregistrement parente avant '
        'd’envoyer ce mobilier.',
      );
    }

    final fieldAnswersRaw = action.payload['fieldAnswers'];
    final fieldAnswers = fieldAnswersRaw is Map
        ? Map<String, dynamic>.from(fieldAnswersRaw)
        : <String, dynamic>{};

    final created = await _auth.createMobilier(
      recordingUnitId: recordingUnitId,
      specimenTypeConceptId: typeId,
      fieldAnswers: fieldAnswers,
    );

    final serverId = created.id.trim();
    if (localId != null &&
        localId.isNotEmpty &&
        MobilierLocalId.isLocalListId(localId) &&
        serverId.isNotEmpty) {
      await _db.remapMobilierResourceId(
        fromResourceId: localId,
        toResourceId: serverId,
      );
    }

    await MobilierListStore(auth: _auth, db: _db).upsertLocal(
      item: created,
      recordingUnitId: recordingUnitId,
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
