import '../../features/projects/documents/document_tmp_models.dart';
import '../../features/projects/mobiliers/mobilier_local_id.dart';
import '../../features/projects/recording_units/recording_unit_local_id.dart';
import 'sync_action_models.dart';
import 'sync_conflict_payload.dart';

/// Ligne affichée dans le panneau « actions à synchroniser ».
class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.sortKey,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusLabel,
    this.errorMessage,
    this.createdAt,
    this.outboxActionId,
    this.documentLocalId,
  });

  final String id;
  final int sortKey;
  final SyncQueueItemSource source;
  final String title;
  final String subtitle;
  final String status;
  final String statusLabel;
  final String? errorMessage;
  final DateTime? createdAt;

  /// Action outbox (`sync_actions.action_id`).
  final String? outboxActionId;

  /// Document local (`documents_tmp.local_id`).
  final String? documentLocalId;

  /// Suppression autorisée (échec ou conflit).
  bool get canDelete =>
      status == SyncActionStatus.failed ||
      status == SyncActionStatus.conflict;

  /// Résolution guidée disponible (conflit outbox).
  bool get canResolve =>
      status == SyncActionStatus.conflict && outboxActionId != null;

  SyncConflictPayload? get conflictPayload =>
      SyncConflictPayload.tryParse(errorMessage);

  /// Message affiché dans la liste (jamais le JSON brut d’un conflit).
  String? get listErrorMessage {
    final raw = errorMessage?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (status == SyncActionStatus.conflict || conflictPayload != null) {
      final custom = conflictPayload?.message?.trim();
      if (custom != null && custom.isNotEmpty) return custom;
      return 'La fiche a été modifiée sur le serveur. '
          'Ouvrez le détail pour comparer les champs.';
    }

    if (raw.startsWith('{') || raw.startsWith('[')) return null;
    return raw;
  }

  factory SyncQueueItem.fromSyncAction(SyncActionEntry action) {
    final payload = action.payload;
    final projectId = payload['projectId']?.toString();
    final entityId =
        action.serverEntityId ?? action.localEntityId ?? '—';

    final buffer = StringBuffer(_formatEntityId(entityId));
    if (projectId != null && projectId.trim().isNotEmpty) {
      buffer.write(' · projet ${_shortId(projectId)}');
    }

    return SyncQueueItem(
      id: 'action:${action.actionId}',
      sortKey: action.sequence,
      source: SyncQueueItemSource.outbox,
      title: '${_operationLabel(action.operation)} — '
          '${_entityTypeLabel(action.entityType)}',
      subtitle: buffer.toString(),
      status: action.status,
      statusLabel: _statusLabel(action.status),
      errorMessage: action.errorMessage,
      createdAt: action.createdAt,
      outboxActionId: action.actionId,
    );
  }

  factory SyncQueueItem.fromDocument(DocumentTmpEntry doc) {
    final parent = doc.parentType == DocumentTmpParentType.recordingUnit
        ? 'UE'
        : 'Projet';

    return SyncQueueItem(
      id: 'doc:${doc.localId}',
      sortKey: (doc.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      source: SyncQueueItemSource.document,
      title: 'Document — ${doc.title}',
      subtitle: '$parent · ${_shortId(doc.parentId)}',
      status: doc.status,
      statusLabel: _statusLabel(doc.status),
      errorMessage: doc.uploadError,
      createdAt: doc.createdAt,
      documentLocalId: doc.localId,
    );
  }

  static String _operationLabel(String operation) {
    return switch (operation) {
      SyncOperation.create => 'Création',
      SyncOperation.update => 'Modification',
      SyncOperation.delete => 'Suppression',
      _ => operation,
    };
  }

  static String _entityTypeLabel(String entityType) {
    return switch (entityType) {
      SyncEntityType.recordingUnit => 'Unité d’enregistrement',
      SyncEntityType.project => 'Projet',
      SyncEntityType.document => 'Document',
      SyncEntityType.mobilier => 'Mobilier',
      _ => entityType,
    };
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'En attente',
      'uploading' => 'Envoi en cours',
      'failed' => 'Échec',
      'conflict' => 'Conflit',
      'synced' => 'Synchronisé',
      _ => status,
    };
  }

  static String _formatEntityId(String id) {
    if (RecordingUnitLocalId.isLocalListId(id) ||
        MobilierLocalId.isLocalListId(id)) {
      return 'brouillon local (${_shortId(id)})';
    }
    return _shortId(id);
  }

  static String _shortId(String id) {
    final s = id.trim();
    if (s.length <= 28) return s;
    return '${s.substring(0, 12)}…${s.substring(s.length - 8)}';
  }
}

enum SyncQueueItemSource { outbox, document }
