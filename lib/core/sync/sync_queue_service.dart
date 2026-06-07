import '../database/app_database.dart';
import '../../features/projects/documents/document_tmp_models.dart';
import '../../features/projects/mobiliers/mobilier_local_id.dart';
import '../../features/projects/recording_units/recording_unit_local_id.dart';
import 'outbox_store.dart';
import 'sync_action_models.dart';
import 'sync_conflict_resolver.dart';
import 'sync_queue_models.dart';

/// Charge et gère la file d’attente (outbox + documents en attente).
class SyncQueueService {
  SyncQueueService(this._db, {SyncConflictResolver? conflictResolver})
      : _conflictResolver = conflictResolver;

  final AppDatabase _db;
  final SyncConflictResolver? _conflictResolver;

  Future<List<SyncQueueItem>> loadItems() async {
    final actions = await OutboxStore(_db).pendingActions();
    final docRows = await _db.queueUploadDocumentsTmp();

    final items = <SyncQueueItem>[
      ...actions.map(SyncQueueItem.fromSyncAction),
      ...docRows.map(
        (row) => SyncQueueItem.fromDocument(DocumentTmpEntry.fromRow(row)),
      ),
    ];

    items.sort((a, b) {
      final byKey = a.sortKey.compareTo(b.sortKey);
      if (byKey != 0) return byKey;
      return a.title.compareTo(b.title);
    });
    return items;
  }

  /// Retire une opération en échec ou en conflit de la file.
  Future<void> removeFailedItem(SyncQueueItem item) async {
    if (!item.canDelete) {
      throw StateError(
        'Seules les opérations en échec ou en conflit peuvent être supprimées.',
      );
    }

    switch (item.source) {
      case SyncQueueItemSource.outbox:
        final actionId = item.outboxActionId;
        if (actionId == null || actionId.isEmpty) {
          throw StateError('Identifiant d’action introuvable.');
        }
        await _removeOutboxAction(actionId);
      case SyncQueueItemSource.document:
        final localId = item.documentLocalId;
        if (localId == null || localId.isEmpty) {
          throw StateError('Identifiant de document local introuvable.');
        }
        await _db.deleteDocumentTmp(localId);
    }
  }

  Future<void> _removeOutboxAction(String actionId) async {
    final row = await _db.syncActionById(actionId);
    if (row == null) return;

    if (row.operation == SyncOperation.create) {
      final localId = row.localEntityId?.trim();
      if (localId != null && localId.isNotEmpty) {
        if (row.entityType == SyncEntityType.recordingUnit &&
            RecordingUnitLocalId.isLocalListId(localId)) {
          await _db.deleteRecordingUnitByResourceId(localId);
        } else if (row.entityType == SyncEntityType.mobilier &&
            MobilierLocalId.isLocalListId(localId)) {
          await _db.deleteMobilierByResourceId(localId);
        }
      }
    }

    await _db.deleteSyncAction(actionId);
  }

  Future<SyncActionEntry?> outboxActionForItem(SyncQueueItem item) async {
    final actionId = item.outboxActionId;
    if (actionId == null || actionId.isEmpty) return null;
    final row = await _db.syncActionById(actionId);
    if (row == null) return null;
    return SyncActionEntry.fromRow(row);
  }

  Future<void> acceptServerVersion(SyncActionEntry action) async {
    final resolver = _conflictResolver;
    if (resolver == null) {
      throw StateError('Résolution de conflit indisponible.');
    }
    await resolver.acceptServerVersion(action);
  }

  Future<void> retryLocalChanges(SyncActionEntry action) async {
    final resolver = _conflictResolver;
    if (resolver == null) {
      throw StateError('Résolution de conflit indisponible.');
    }
    await resolver.retryLocalChanges(action);
  }
}
