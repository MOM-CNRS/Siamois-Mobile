import 'dart:convert';

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

  Future<SyncActionEntry> enqueueRecordingUnitUpdate({
    required String recordingUnitId,
    required Map<String, dynamic> fieldAnswers,
    required int? baseServerRevision,
    String? projectId,
  }) async {
    final actionId = _newActionId();
    final sequence = await _db.nextSyncActionSequence();
    final payload = jsonEncode({
      'fieldAnswers': fieldAnswers,
      if (projectId != null) 'projectId': projectId,
    });

    await _db.insertSyncAction(
      actionId: actionId,
      sequence: sequence,
      operation: SyncOperation.update,
      entityType: SyncEntityType.recordingUnit,
      serverEntityId: recordingUnitId,
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
}
