import 'dart:convert';

import '../../features/auth/auth_repository.dart';
import '../../features/projects/form/spatial_unit_models.dart';
import '../../features/projects/project_detail_models.dart';
import '../../features/projects/recording_units/recording_unit_field_answers_merge.dart';
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

    final placeActions =
        pending.where((a) => a.entityType == SyncEntityType.place).toList();
    final otherActions =
        pending.where((a) => a.entityType != SyncEntityType.place).toList();
    final ordered = [...placeActions, ...otherActions];

    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    for (final action in ordered) {
      await _db.updateSyncActionStatus(
        actionId: action.actionId,
        status: SyncActionStatus.uploading,
      );

      try {
        switch (action.entityType) {
          case SyncEntityType.place:
            if (action.operation == SyncOperation.create) {
              await _syncPlaceCreate(action);
            } else if (action.operation == SyncOperation.update) {
              await _syncPlaceUpdate(action);
            } else if (action.operation == SyncOperation.delete) {
              await _syncPlaceDelete(action);
            } else {
              throw AuthException(
                'Opération « ${action.operation} » non prise en charge pour les lieux.',
              );
            }
            break;
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

  Future<void> _syncPlaceCreate(SyncActionEntry action) async {
    final localIdRaw = action.localEntityId ?? action.payload['localPlaceId'];
    final localId = localIdRaw is int
        ? localIdRaw
        : int.tryParse(localIdRaw?.toString() ?? '');
    final orgRaw = action.payload['organizationId'];
    final orgId = orgRaw is int
        ? orgRaw
        : orgRaw is num
            ? orgRaw.toInt()
            : int.tryParse(orgRaw?.toString() ?? '');
    final name = action.payload['name']?.toString().trim() ?? '';
    final typeRaw = action.payload['typeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');

    if (localId == null || orgId == null || name.isEmpty || typeId == null) {
      throw AuthException(
        'Création lieu : données incomplètes dans la file d’attente.',
      );
    }

    FullAddressOption? address;
    final addressRaw = action.payload['address'];
    if (addressRaw is Map) {
      address = FullAddressOption.fromJson(addressRaw);
    }

    final created = await _auth.createSpatialUnit(
      CreateSpatialUnitRequest(
        organizationId: orgId,
        name: name,
        typeConceptId: typeId,
        address: address,
      ),
    );

    await _db.remapCachedPlaceId(
      organisationId: orgId,
      fromPlaceId: localId,
      toPlaceId: created.id,
      name: created.label,
      code: created.code,
    );
    await _db.remapLocalPlaceIdInOutboxPayloads(
      fromPlaceId: localId,
      toPlaceId: created.id,
    );
  }

  Future<void> _syncPlaceUpdate(SyncActionEntry action) async {
    final placeId = int.tryParse(
      (action.serverEntityId ?? action.localEntityId ?? '').trim(),
    );
    final orgRaw = action.payload['organizationId'];
    final orgId = orgRaw is int
        ? orgRaw
        : orgRaw is num
            ? orgRaw.toInt()
            : int.tryParse(orgRaw?.toString() ?? '');
    final name = action.payload['name']?.toString().trim() ?? '';
    final typeRaw = action.payload['typeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');

    if (placeId == null || orgId == null || name.isEmpty || typeId == null) {
      throw AuthException(
        'Modification lieu : données incomplètes dans la file d’attente.',
      );
    }

    FullAddressOption? address;
    final addressRaw = action.payload['address'];
    if (addressRaw is Map) {
      address = FullAddressOption.fromJson(addressRaw);
    }

    final updated = await _auth.updateSpatialUnit(
      placeId: placeId,
      request: CreateSpatialUnitRequest(
        organizationId: orgId,
        name: name,
        typeConceptId: typeId,
        address: address,
      ),
    );

    await _db.upsertCachedPlace(
      organisationId: orgId,
      placeId: updated.id,
      name: updated.label,
      code: updated.code,
      pendingSync: false,
      typeConceptId: typeId,
      addressJson: address == null ? null : jsonEncode(address.toJson()),
    );
  }

  Future<void> _syncPlaceDelete(SyncActionEntry action) async {
    final placeId = int.tryParse(
      (action.serverEntityId ?? action.localEntityId ?? '').trim(),
    );
    final orgRaw = action.payload['organizationId'];
    final orgId = orgRaw is int
        ? orgRaw
        : orgRaw is num
            ? orgRaw.toInt()
            : int.tryParse(orgRaw?.toString() ?? '');

    if (placeId == null || orgId == null) {
      throw AuthException(
        'Suppression lieu : données incomplètes dans la file d’attente.',
      );
    }

    await _auth.deleteSpatialUnit(
      organizationId: orgId,
      placeId: placeId,
    );
    await _db.deleteCachedPlace(
      organisationId: orgId,
      placeId: placeId,
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

    final merged = RecordingUnitFieldAnswersMerge.apply(
      detail: detail,
      fieldAnswers: fieldAnswers,
    );

    final serverId = RecordingUnitDetailStore.recordingUnitIdFromDetail(merged);
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
      merged,
      projectId: projectId,
    );

    final item = RecordingUnitItem.fromJson(merged.recordingUnit);
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
      serverRevision: readRecordingUnitSyncRevision(merged.recordingUnit),
      detailApiData: merged.toApiData(),
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
