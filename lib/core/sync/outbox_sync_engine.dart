import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/projects/form/spatial_unit_local_id.dart';
import '../../features/projects/form/spatial_unit_models.dart';
import '../../features/projects/form/project_form_models.dart';
import '../../features/projects/project_detail_models.dart';
import '../../features/projects/project_detail_store.dart';
import '../../features/projects/project_local_id.dart';
import '../../features/projects/project_models.dart';
import '../../features/projects/project_offline_create.dart';
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

  Future<OutboxSyncResult> syncAll({
    void Function(SyncActionEntry action, int index, int total)? onActionStarted,
  }) async {
    await _db.resetSyncActionsForRetry();
    final outbox = OutboxStore(_db);
    final pending = await outbox.pendingActions();
    if (pending.isEmpty) {
      return const OutboxSyncResult(synced: 0, failed: 0, conflicts: 0);
    }

    final placeActions =
        pending.where((a) => a.entityType == SyncEntityType.place).toList();
    final projectActions =
        pending.where((a) => a.entityType == SyncEntityType.project).toList();
    final otherActions = pending
        .where(
          (a) =>
              a.entityType != SyncEntityType.place &&
              a.entityType != SyncEntityType.project,
        )
        .toList();
    final ordered = [...placeActions, ...projectActions, ...otherActions];

    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    for (var i = 0; i < ordered.length; i++) {
      final row = await _db.syncActionById(ordered[i].actionId);
      if (row == null) continue;
      final action = SyncActionEntry.fromRow(row);
      onActionStarted?.call(action, i, ordered.length);

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
          case SyncEntityType.project:
            if (action.operation == SyncOperation.create) {
              await _syncProjectCreate(action);
            } else if (action.operation == SyncOperation.delete) {
              await _syncProjectDelete(action);
            } else {
              throw AuthException(
                'Opération « ${action.operation} » non prise en charge pour les projets.',
              );
            }
            break;
          case SyncEntityType.recordingUnit:
            if (action.operation == SyncOperation.create) {
              await _syncRecordingUnitCreate(action);
            } else if (action.operation == SyncOperation.update) {
              await _syncRecordingUnitUpdate(action);
            } else if (action.operation == SyncOperation.delete) {
              await _syncRecordingUnitDelete(action);
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
        if (kDebugMode) {
          debugPrint(
            '[Siamois Sync] Échec ${action.entityType}/${action.operation} '
            '(${action.actionId}): ${e.message}',
          );
        }
        await _db.updateSyncActionStatus(
          actionId: action.actionId,
          status: SyncActionStatus.failed,
          errorMessage: e.message,
        );
        failed++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[Siamois Sync] Échec ${action.entityType}/${action.operation} '
            '(${action.actionId}): $e',
          );
        }
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

  Future<SyncActionEntry> _reloadAction(SyncActionEntry action) async {
    final row = await _db.syncActionById(action.actionId);
    if (row == null) return action;
    return SyncActionEntry.fromRow(row);
  }

  void _assertNoUnresolvedLocalPlaceIds({
    required Map<String, dynamic> fieldAnswers,
    required List<int> spatialIds,
  }) {
    final unresolved = <int>{};

    void check(dynamic raw) {
      final id = _parsePlaceId(raw);
      if (id != null && SpatialUnitLocalId.isLocalId(id)) {
        unresolved.add(id);
      }
    }

    for (final value in fieldAnswers.values) {
      if (value is List) {
        for (final item in value) {
          check(item);
        }
      } else {
        check(value);
      }
    }
    for (final id in spatialIds) {
      check(id);
    }

    if (unresolved.isEmpty) return;

    final labels = unresolved.map((id) => id.toString()).join(', ');
    throw AuthException(
      'Lieux locaux non synchronisés ($labels). '
      'Synchronisez d’abord les lieux en attente, puis réessayez.',
    );
  }

  int? _parsePlaceId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Set<int> _collectLocalPlaceIds(Map<String, dynamic> payloadMap) {
    final unresolved = <int>{};

    void check(dynamic raw) {
      final id = _parsePlaceId(raw);
      if (id != null && SpatialUnitLocalId.isLocalId(id)) {
        unresolved.add(id);
      }
    }

    final spatialRaw = payloadMap['spatialContextSpatialUnitIds'];
    if (spatialRaw is List) {
      for (final item in spatialRaw) {
        check(item);
      }
    }

    final fieldAnswers = payloadMap['fieldAnswers'];
    if (fieldAnswers is Map) {
      for (final value in fieldAnswers.values) {
        if (value is List) {
          for (final item in value) {
            check(item);
          }
        } else {
          check(value);
        }
      }
    }

    return unresolved;
  }

  Future<SyncActionEntry> _ensureReferencedPlacesSynced({
    required SyncActionEntry action,
    required int orgId,
  }) async {
    var current = action;
    var localIds = _collectLocalPlaceIds(current.payload);

    while (localIds.isNotEmpty) {
      for (final localPlaceId in localIds) {
        await _syncLocalPlaceIfNeeded(
          localPlaceId: localPlaceId,
          orgId: orgId,
        );
      }
      current = await _reloadAction(action);
      localIds = _collectLocalPlaceIds(current.payload);
    }

    return current;
  }

  Future<void> _syncLocalPlaceIfNeeded({
    required int localPlaceId,
    required int orgId,
  }) async {
    final cached = await _db.cachedPlaceRow(
      organisationId: orgId,
      placeId: localPlaceId,
    );
    if (cached != null && !SpatialUnitLocalId.isLocalId(cached.placeId)) {
      return;
    }

    final pending = await OutboxStore(_db).pendingActions();
    SyncActionEntry? placeAction;
    for (final candidate in pending) {
      if (candidate.entityType == SyncEntityType.place &&
          candidate.operation == SyncOperation.create &&
          candidate.localEntityId == localPlaceId.toString()) {
        placeAction = candidate;
        break;
      }
    }

    if (placeAction != null) {
      final fresh = await _reloadAction(placeAction);
      await _syncPlaceCreate(fresh);
      await _db.deleteSyncAction(fresh.actionId);
      return;
    }

    if (cached == null) {
      throw AuthException(
        'Lieu local $localPlaceId introuvable. '
        'Recréez le lieu ou supprimez l’action en échec.',
      );
    }

    final typeId = cached.typeConceptId;
    if (typeId == null) {
      throw AuthException(
        'Lieu « ${cached.name} » incomplet (type manquant). '
        'Modifiez-le dans Gestion des lieux avant de synchroniser.',
      );
    }

    FullAddressOption? address;
    final addressJson = cached.addressJson;
    if (addressJson != null && addressJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(addressJson);
        address = FullAddressOption.fromJson(decoded);
      } catch (_) {}
    }

    final created = await _auth.createSpatialUnit(
      CreateSpatialUnitRequest(
        organizationId: orgId,
        name: cached.name,
        typeConceptId: typeId,
        address: address,
      ),
    );

    await _db.remapCachedPlaceId(
      organisationId: orgId,
      fromPlaceId: localPlaceId,
      toPlaceId: created.id,
      name: created.label,
      code: created.code,
    );
    await _db.remapLocalPlaceIdInOutboxPayloads(
      fromPlaceId: localPlaceId,
      toPlaceId: created.id,
    );
  }

  Future<void> _syncProjectCreate(SyncActionEntry action) async {
    final localId = action.localEntityId?.trim();

    final orgRaw = action.payload['organizationId'];
    final orgId = orgRaw is int
        ? orgRaw
        : orgRaw is num
            ? orgRaw.toInt()
            : int.tryParse(orgRaw?.toString() ?? '');

    if (orgId == null) {
      throw AuthException(
        'Création projet : organisation manquante dans la file d’attente.',
      );
    }

    action = await _ensureReferencedPlacesSynced(
      action: action,
      orgId: orgId,
    );

    final payloadMap = action.payload;

    final name = payloadMap['name']?.toString().trim() ?? '';
    final identifier = payloadMap['identifier']?.toString().trim() ?? '';
    final typeRaw = payloadMap['typeConceptId'];
    final typeId = typeRaw is int
        ? typeRaw
        : typeRaw is num
            ? typeRaw.toInt()
            : int.tryParse(typeRaw?.toString() ?? '');

    if (name.isEmpty || identifier.isEmpty || typeId == null) {
      throw AuthException(
        'Création projet : données incomplètes dans la file d’attente.',
      );
    }

    DateTime? beginDate;
    final beginRaw = payloadMap['beginDate']?.toString();
    if (beginRaw != null && beginRaw.isNotEmpty) {
      beginDate = DateTime.tryParse(beginRaw);
    }

    DateTime? endDate;
    final endRaw = payloadMap['endDate']?.toString();
    if (endRaw != null && endRaw.isNotEmpty) {
      endDate = DateTime.tryParse(endRaw);
    }

    final spatialRaw = payloadMap['spatialContextSpatialUnitIds'];
    final spatialIds = <int>[];
    if (spatialRaw is List) {
      for (final item in spatialRaw) {
        if (item is int) {
          spatialIds.add(item);
        } else if (item is num) {
          spatialIds.add(item.toInt());
        }
      }
    }

    final fieldAnswersRaw = payloadMap['fieldAnswers'];
    final fieldAnswers = fieldAnswersRaw is Map
        ? Map<String, dynamic>.from(fieldAnswersRaw)
        : <String, dynamic>{};

    _assertNoUnresolvedLocalPlaceIds(
      fieldAnswers: fieldAnswers,
      spatialIds: spatialIds,
    );

    final payload = ProjectCreatePayload(
      organizationId: orgId,
      name: name,
      identifier: identifier,
      typeConceptId: typeId,
      beginDate: beginDate,
      endDate: endDate,
      spatialContextSpatialUnitIds: spatialIds,
      fieldAnswers: fieldAnswers,
    );

    ProjectSummary created;
    try {
      created = await _auth.createProjectFromPayload(payload);
    } on AuthException catch (e) {
      if (!_isProjectAlreadyExistsError(e.message)) rethrow;
      if (kDebugMode) {
        debugPrint(
          '[Siamois Sync] Projet « $name » déjà sur le serveur — '
          'rattachement de l’identifiant local.',
        );
      }
      created = await _resolveExistingProject(
        orgId: orgId,
        identifier: identifier,
        name: name,
      );
    }

    await _finalizeProjectCreate(
      created: created,
      localId: localId,
      orgId: orgId,
    );
  }

  bool _isProjectAlreadyExistsError(String? message) {
    final lower = message?.toLowerCase() ?? '';
    return lower.contains('already exist') ||
        lower.contains('already exists') ||
        lower.contains('existe déjà');
  }

  Future<ProjectSummary> _resolveExistingProject({
    required int orgId,
    required String identifier,
    required String name,
  }) async {
    final cached = await _findExistingProjectLocally(
      orgId: orgId,
      identifier: identifier,
      name: name,
    );
    if (cached != null) return cached;

    final remote = await _auth.fetchAccessibleProjects(organizationId: orgId);
    final match = _pickMatchingProject(
      projects: remote,
      identifier: identifier,
      name: name,
    );
    if (match != null) return match;

    throw AuthException(
      'Le projet « $name » existe déjà sur le serveur mais n’a pas pu être '
      'retrouvé. Actualisez la liste des projets puis réessayez.',
    );
  }

  Future<ProjectSummary?> _findExistingProjectLocally({
    required int orgId,
    required String identifier,
    required String name,
  }) async {
    final rows = await _db.projectsForOrganisation(orgId);
    for (final row in rows) {
      if (ProjectLocalId.isLocalListId(row.id)) continue;
      if (!_projectRowMatches(row, identifier: identifier, name: name)) {
        continue;
      }
      return ProjectSummary(
        id: row.id,
        name: row.nom,
        identifier: row.identifiant,
        fullIdentifier: row.fullIdentifier,
        recordingUnitCount: row.recordingUnitCount,
      );
    }
    return null;
  }

  bool _projectRowMatches(
    Projet row, {
    required String identifier,
    required String name,
  }) {
    final idNorm = identifier.trim().toLowerCase();
    final nameNorm = name.trim().toLowerCase();
    if (row.identifiant?.trim().toLowerCase() == idNorm) return true;
    if (row.fullIdentifier?.trim().toLowerCase() == idNorm) return true;
    return row.nom.trim().toLowerCase() == nameNorm;
  }

  ProjectSummary? _pickMatchingProject({
    required List<ProjectSummary> projects,
    required String identifier,
    required String name,
  }) {
    final idNorm = identifier.trim().toLowerCase();
    for (final project in projects) {
      if (project.identifier?.trim().toLowerCase() == idNorm) return project;
      if (project.fullIdentifier?.trim().toLowerCase() == idNorm) return project;
    }
    final nameNorm = name.trim().toLowerCase();
    for (final project in projects) {
      if (project.name.trim().toLowerCase() == nameNorm) return project;
    }
    return null;
  }

  Future<void> _finalizeProjectCreate({
    required ProjectSummary created,
    required String? localId,
    required int orgId,
  }) async {
    final serverId = created.storageId;

    if (localId != null &&
        localId.isNotEmpty &&
        ProjectLocalId.isLocalListId(localId)) {
      await _db.remapProjectResourceId(
        fromResourceId: localId,
        toResourceId: serverId,
        organisationId: orgId,
      );
    }

    await _db.upsertProjet(project: created, organisationId: orgId);

    final detailStore = ProjectDetailStore(auth: _auth, db: _db);
    try {
      final detail = await _auth.fetchProjectDetail(serverId);
      await detailStore.saveAfterMutation(serverId, detail);
    } catch (_) {
      await detailStore.saveAfterMutation(
        serverId,
        ProjectOfflineCreate.detailFromSummary(created),
      );
    }
  }

  Future<void> _syncProjectDelete(SyncActionEntry action) async {
    final projectId = (action.serverEntityId ?? action.localEntityId ?? '')
        .trim();
    if (projectId.isEmpty) {
      throw AuthException(
        'Suppression projet : identifiant manquant dans la file d’attente.',
      );
    }

    await _auth.deleteProject(projectId: projectId);
  }

  Future<void> _syncRecordingUnitDelete(SyncActionEntry action) async {
    final recordingUnitId =
        (action.serverEntityId ?? action.localEntityId ?? '').trim();
    if (recordingUnitId.isEmpty) {
      throw AuthException(
        'Suppression UE : identifiant manquant dans la file d’attente.',
      );
    }

    await _auth.deleteRecordingUnit(recordingUnitId);
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
      placeId: placeId,
      organizationId: orgId,
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

    if (ProjectLocalId.isLocalListId(actionUnitId)) {
      throw AuthException(
        'Synchronisez d’abord le projet parent avant d’envoyer '
        'cette unité d’enregistrement.',
      );
    }

    if (actionUnitId.isEmpty || typeId == null) {
      throw AuthException('Création UE : données incomplètes dans la file d’attente.');
    }

    final fieldAnswersRaw = action.payload['fieldAnswers'];
    final fieldAnswers = fieldAnswersRaw is Map
        ? Map<String, dynamic>.from(fieldAnswersRaw)
        : <String, dynamic>{};

    _assertNoUnresolvedLocalPlaceIds(
      fieldAnswers: fieldAnswers,
      spatialIds: const [],
    );

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
