import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/entity_snapshot_store.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'recording_unit_detail_models.dart';

/// Détail UE : API en ligne puis cache SQLite, sinon lecture locale.
class RecordingUnitDetailStore {
  RecordingUnitDetailStore({
    required AuthRepository auth,
    required AppDatabase db,
    ConnectivityService? connectivity,
  })  : _auth = auth,
        _db = db,
        _connectivity = connectivity ?? auth.connectivity;

  final AuthRepository _auth;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<bool> get _isOnline async {
    final base = _auth.lastUsedBaseUrl;
    if (base.isEmpty) return false;
    return _connectivity.isOnline(base);
  }

  Future<RecordingUnitMobileDetail> load(String recordingUnitId) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant UE invalide.');
    }

    if (await _isOnline) {
      try {
        final detail = await _auth.fetchRecordingUnitDetail(key);
        await _persistDetail(key, detail);
        await EntitySnapshotStore(_db).saveRecordingUnitSnapshot(
          entityId: key,
          serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
          detailApiData: detail.toApiData(),
        );
        return detail;
      } on AuthException {
        return _loadFromLocal(key);
      }
    }

    return _loadFromLocal(key);
  }

  Future<void> _persistDetail(
    String resourceId,
    RecordingUnitMobileDetail detail,
  ) async {
    await _db.replaceRecordingUnitDetail(
      resourceId: resourceId,
      detailJson: jsonEncode(detail.toApiData()),
      typeConceptId: detail.typeConceptId,
    );
  }

  Future<RecordingUnitMobileDetail> _loadFromLocal(String resourceId) async {
    final row = await _db.recordingUnitDetailRow(resourceId);
    if (row == null) {
      throw AuthException(
        'Détail UE indisponible hors ligne. Consultez cette UE en ligne au moins une fois.',
      );
    }
    final decoded = jsonDecode(row.detailJson);
    if (decoded is! Map) {
      throw AuthException('Cache UE corrompu.');
    }
    return RecordingUnitMobileDetail.fromApiData(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<RecordingUnitMobileDetail> saveAfterMutation(
    RecordingUnitMobileDetail detail, {
    String? projectId,
  }) async {
    final resourceId = recordingUnitIdFromDetail(detail);
    await _persistDetail(resourceId, detail);

    if (projectId != null && projectId.trim().isNotEmpty) {
      final item = RecordingUnitItem.fromJson(detail.recordingUnit);
      if (item.id.isNotEmpty) {
        await _db.upsertRecordingUnit(
          item: item,
          projectId: projectId.trim(),
          typeConceptId: detail.typeConceptId,
        );
      }
    }

    return detail;
  }

  static String recordingUnitIdFromDetail(RecordingUnitMobileDetail detail) {
    return _string(detail.recordingUnit['resourceId']) ??
        _string(detail.recordingUnit['fullIdentifier']) ??
        _string(detail.recordingUnit['id']) ??
        detail.displayCode;
  }

  Future<void> removeLocal(String resourceId) async {
    await _db.deleteRecordingUnitByResourceId(resourceId);
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
