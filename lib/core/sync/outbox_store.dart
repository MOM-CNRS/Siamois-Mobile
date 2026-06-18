import 'dart:convert';

import '../../features/projects/form/recording_unit_option.dart';
import '../../features/projects/form/spatial_unit_models.dart';
import '../database/app_database.dart';
import 'sync_action_models.dart';

/// Enfile des mutations locales (outbox).
class OutboxStore {
  OutboxStore(this._db);

  final AppDatabase _db;

  static String _newActionId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  Future<SyncActionEntry> enqueueRecordingUnitCreate({
    required String localRecordingUnitId,
    required String actionUnitId,
    required int recordingUnitTypeConceptId,
    required Map<String, dynamic> fieldAnswers,
    String? projectId,
  }) async {
    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    final payload = jsonEncode({
      'actionUnitId': actionUnitId.trim(),
      'recordingUnitTypeConceptId': recordingUnitTypeConceptId,
      'fieldAnswers': fieldAnswers,
      if (projectId != null) 'projectId': projectId,
    });

    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.create,
      entityType: SyncEntityType.recordingUnit,
      localEntityId: localRecordingUnitId,
      payloadJson: payload,
      status: SyncActionStatus.pending,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<SyncActionEntry> enqueueMobilierCreate({
    required String localMobilierId,
    required String recordingUnitId,
    required int specimenTypeConceptId,
    required Map<String, dynamic> fieldAnswers,
  }) async {
    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    final payload = jsonEncode({
      'recordingUnitId': recordingUnitId.trim(),
      'specimenTypeConceptId': specimenTypeConceptId,
      'fieldAnswers': fieldAnswers,
    });

    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.create,
      entityType: SyncEntityType.mobilier,
      localEntityId: localMobilierId,
      payloadJson: payload,
      status: SyncActionStatus.pending,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<SyncActionEntry> enqueuePlaceCreate({
    required int localPlaceId,
    required int organizationId,
    required CreateSpatialUnitRequest request,
  }) async {
    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    final payload = jsonEncode({
      'organizationId': organizationId,
      ...request.toJson(),
    });

    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.create,
      entityType: SyncEntityType.place,
      localEntityId: localPlaceId.toString(),
      payloadJson: payload,
      status: SyncActionStatus.pending,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<void> updatePlaceCreate({
    required int localPlaceId,
    required int organizationId,
    required CreateSpatialUnitRequest request,
  }) async {
    final pending = await pendingActions();
    final createAction = pending.firstWhere(
      (action) =>
          action.entityType == SyncEntityType.place &&
          action.operation == SyncOperation.create &&
          action.localEntityId == localPlaceId.toString(),
      orElse: () => throw StateError('create action not found'),
    );

    await _db.updateSyncActionPayload(
      actionId: createAction.actionId,
      payloadJson: jsonEncode({
        'organizationId': organizationId,
        ...request.toJson(),
      }),
    );
  }

  Future<SyncActionEntry> enqueuePlaceUpdate({
    required int placeId,
    required int organizationId,
    required CreateSpatialUnitRequest request,
  }) async {
    final entityKey = placeId.toString();
    final pending = await pendingActions();
    final existingUpdates = pending
        .where(
          (action) =>
              action.entityType == SyncEntityType.place &&
              action.operation == SyncOperation.update &&
              (action.serverEntityId?.trim() ?? '') == entityKey,
        )
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    if (existingUpdates.isNotEmpty) {
      final primary = existingUpdates.first;
      await _db.updateSyncActionPayload(
        actionId: primary.actionId,
        payloadJson: jsonEncode({
          'organizationId': organizationId,
          ...request.toJson(),
        }),
      );
      for (final duplicate in existingUpdates.skip(1)) {
        await _db.deleteSyncAction(duplicate.actionId);
      }
      final rows = await _db.pendingSyncActions();
      final row = rows.firstWhere((r) => r.actionId == primary.actionId);
      return SyncActionEntry.fromRow(row);
    }

    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.update,
      entityType: SyncEntityType.place,
      serverEntityId: entityKey,
      payloadJson: jsonEncode({
        'organizationId': organizationId,
        ...request.toJson(),
      }),
      status: SyncActionStatus.pending,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<SyncActionEntry> enqueuePlaceDelete({
    required int placeId,
    required int organizationId,
  }) async {
    final entityKey = placeId.toString();
    final pending = await pendingActions();
    for (final action in pending) {
      if (action.entityType != SyncEntityType.place) continue;
      if (action.localEntityId == entityKey ||
          action.serverEntityId == entityKey) {
        await _db.deleteSyncAction(action.actionId);
      }
    }

    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.delete,
      entityType: SyncEntityType.place,
      serverEntityId: entityKey,
      payloadJson: jsonEncode({'organizationId': organizationId}),
      status: SyncActionStatus.pending,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<void> removeLocalPlaceActions(int localPlaceId) async {
    final key = localPlaceId.toString();
    final pending = await pendingActions();
    for (final action in pending) {
      if (action.entityType == SyncEntityType.place &&
          action.localEntityId == key) {
        await _db.deleteSyncAction(action.actionId);
      }
    }
  }

  Future<SyncActionEntry> enqueueRecordingUnitUpdate({
    required String recordingUnitId,
    required Map<String, dynamic> fieldAnswers,
    required int? baseServerRevision,
    String? projectId,
  }) async {
    final sanitizedAnswers = _sanitizeRecordingUnitFieldAnswers(fieldAnswers);
    final entityKey = recordingUnitId.trim();
    final pending = await pendingActions();
    final existingUpdates = pending
        .where(
          (action) =>
              action.entityType == SyncEntityType.recordingUnit &&
              action.operation == SyncOperation.update &&
              (action.serverEntityId?.trim() ?? '') == entityKey,
        )
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    if (existingUpdates.isNotEmpty) {
      final primary = existingUpdates.first;
      final mergedAnswers = <String, dynamic>{};
      for (final action in existingUpdates) {
        final raw = action.payload['fieldAnswers'];
        if (raw is Map) {
          mergedAnswers.addAll(Map<String, dynamic>.from(raw));
        }
      }
      mergedAnswers.addAll(sanitizedAnswers);

      final mergedPayload = Map<String, dynamic>.from(primary.payload);
      mergedPayload['fieldAnswers'] =
          _sanitizeRecordingUnitFieldAnswers(mergedAnswers);
      if (projectId != null) {
        mergedPayload['projectId'] = projectId;
      }

      await _db.updateSyncActionPayload(
        actionId: primary.actionId,
        payloadJson: jsonEncode(mergedPayload),
      );

      for (final duplicate in existingUpdates.skip(1)) {
        await _db.deleteSyncAction(duplicate.actionId);
      }

      final rows = await _db.pendingSyncActions();
      final row = rows.firstWhere((r) => r.actionId == primary.actionId);
      return SyncActionEntry.fromRow(row);
    }

    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    final payload = jsonEncode({
      'fieldAnswers': sanitizedAnswers,
      if (projectId != null) 'projectId': projectId,
    });

    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.update,
      entityType: SyncEntityType.recordingUnit,
      serverEntityId: entityKey,
      payloadJson: payload,
      status: SyncActionStatus.pending,
      baseServerRevision: baseServerRevision,
    );

    final rows = await _db.pendingSyncActions();
    final row = rows.firstWhere((r) => r.actionId == actionId);
    return SyncActionEntry.fromRow(row);
  }

  Future<List<SyncActionEntry>> pendingActions() async {
    final rows = await _db.pendingSyncActions();
    return rows.map(SyncActionEntry.fromRow).toList();
  }

  Future<int> pendingCount() => _db.countPendingSyncActions();

  static Map<String, dynamic> _sanitizeRecordingUnitFieldAnswers(
    Map<String, dynamic> fieldAnswers,
  ) {
    return {
      for (final entry in fieldAnswers.entries)
        entry.key: _looksLikeRecordingUnitList(entry.value)
            ? RecordingUnitOption.dedupeFieldAnswerValue(entry.value)
            : entry.value,
    };
  }

  static bool _looksLikeRecordingUnitList(dynamic raw) {
    if (raw is! List || raw.isEmpty) return false;
    return raw.every((entry) {
      if (entry is num) return true;
      if (entry is! Map) return false;
      final map = Map<String, dynamic>.from(entry);
      return map.containsKey('fullIdentifier') ||
          map.containsKey('resourceId') ||
          map.containsKey('identifier') ||
          map.containsKey('id') ||
          map.containsKey('recordingUnitId');
    });
  }
}
