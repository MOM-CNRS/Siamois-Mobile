import '../../features/projects/recording_units/recording_unit_detail_models.dart';

import 'sync_conflict_payload.dart';

/// Conflit HTTP 409 : révision serveur différente de celle attendue.
class SyncConflictException implements Exception {
  SyncConflictException({
    required this.entityType,
    required this.entityId,
    required this.expectedRevision,
    required this.currentRevision,
    this.serverDetail,
    this.message,
  });

  final String entityType;
  final String entityId;
  final int expectedRevision;
  final int currentRevision;
  final RecordingUnitMobileDetail? serverDetail;
  final String? message;

  @override
  String toString() =>
      message ??
      'Conflit de synchronisation sur $entityType ($entityId) : '
      'révision attendue $expectedRevision, serveur $currentRevision.';

  String encodeForStorage() =>
      SyncConflictPayload.fromException(this).encode();
}
