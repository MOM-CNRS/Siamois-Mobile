import 'dart:convert';

import 'sync_conflict_exception.dart';

/// Données de conflit sérialisées dans `sync_actions.error_message`.
class SyncConflictPayload {
  const SyncConflictPayload({
    required this.entityType,
    required this.entityId,
    required this.expectedRevision,
    required this.currentRevision,
    this.message,
    this.serverState,
  });

  final String entityType;
  final String entityId;
  final int expectedRevision;
  final int currentRevision;
  final String? message;
  final Map<String, dynamic>? serverState;

  factory SyncConflictPayload.fromException(SyncConflictException conflict) {
    return SyncConflictPayload(
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      expectedRevision: conflict.expectedRevision,
      currentRevision: conflict.currentRevision,
      message: conflict.message,
      serverState: conflict.serverDetail?.toApiData(),
    );
  }

  String encode() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'expectedRevision': expectedRevision,
        'currentRevision': currentRevision,
        if (message != null) 'message': message,
        if (serverState != null) 'serverState': serverState,
      };

  static SyncConflictPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      return SyncConflictPayload(
        entityType: map['entityType']?.toString() ?? '',
        entityId: map['entityId']?.toString() ?? '',
        expectedRevision: _intFrom(map['expectedRevision']),
        currentRevision: _intFrom(map['currentRevision']),
        message: map['message']?.toString(),
        serverState: map['serverState'] is Map
            ? Map<String, dynamic>.from(map['serverState'] as Map)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  static int _intFrom(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
