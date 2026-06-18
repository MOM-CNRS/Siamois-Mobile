import 'dart:convert';

import '../database/app_database.dart';

abstract final class SyncOperation {
  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
}

abstract final class SyncEntityType {
  static const project = 'project';
  static const recordingUnit = 'recording_unit';
  static const document = 'document';
  static const mobilier = 'mobilier';
  static const place = 'place';
}

abstract final class SyncActionStatus {
  static const pending = 'pending';
  static const uploading = 'uploading';
  static const synced = 'synced';
  static const failed = 'failed';
  static const conflict = 'conflict';
}

/// Action en file d’attente (outbox).
class SyncActionEntry {
  const SyncActionEntry({
    required this.actionId,
    required this.sequence,
    required this.operation,
    required this.entityType,
    required this.payloadJson,
    required this.status,
    this.localEntityId,
    this.serverEntityId,
    this.parentType,
    this.parentLocalId,
    this.parentServerId,
    this.blobRef,
    this.baseServerRevision,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String actionId;
  final int sequence;
  final String operation;
  final String entityType;
  final String payloadJson;
  final String status;
  final String? localEntityId;
  final String? serverEntityId;
  final String? parentType;
  final String? parentLocalId;
  final String? parentServerId;
  final String? blobRef;
  final int? baseServerRevision;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> get payload {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  factory SyncActionEntry.fromRow(SyncActionRow row) {
    return SyncActionEntry(
      actionId: row.actionId,
      sequence: row.sequence,
      operation: row.operation,
      entityType: row.entityType,
      payloadJson: row.payloadJson,
      status: row.status,
      localEntityId: row.localEntityId,
      serverEntityId: row.serverEntityId,
      parentType: row.parentType,
      parentLocalId: row.parentLocalId,
      parentServerId: row.parentServerId,
      blobRef: row.blobRef,
      baseServerRevision: row.baseServerRevision,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
