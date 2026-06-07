import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/sync/entity_snapshot_store.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_local_id.dart';

/// Détail UE : API si le serveur est joignable, sinon cache SQLite.
class RecordingUnitDetailStore {
  RecordingUnitDetailStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<RecordingUnitMobileDetail> load(
    String recordingUnitId, {
    RecordingUnitItem? summary,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant UE invalide.');
    }

    if (RecordingUnitLocalId.isLocalListId(key)) {
      return _loadFromLocal(key, summary: summary);
    }

    final serverReachable = !(await _auth.isOfflineEnvironment());
    if (serverReachable) {
      try {
        final detail = await _auth.fetchRecordingUnitDetail(key);
        await _persistDetail(key, detail);
        await EntitySnapshotStore(_db).saveRecordingUnitSnapshot(
          entityId: key,
          serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
          detailApiData: detail.toApiData(),
        );
        return detail;
      } on AuthException catch (e) {
        final row = await _db.recordingUnitDetailRow(key);
        if (row != null) {
          return _parseLocalRow(row);
        }
        rethrow;
      }
    }

    return _loadFromLocal(key, summary: summary);
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

  Future<RecordingUnitMobileDetail> _loadFromLocal(
    String resourceId, {
    RecordingUnitItem? summary,
  }) async {
    final row = await _db.recordingUnitDetailRow(resourceId);
    if (row != null) {
      return _parseLocalRow(row);
    }

    final minimal = _minimalFromSummary(summary, resourceId);
    if (minimal != null) return minimal;

    final offline = await _auth.isOfflineEnvironment();
    throw AuthException(
      offline
          ? 'Détail UE indisponible hors ligne. Consultez cette UE en ligne au moins une fois.'
          : 'Impossible de charger le détail de cette UE. Vérifiez votre connexion ou reconnectez-vous.',
    );
  }

  RecordingUnitMobileDetail _parseLocalRow(UniteEnregistrementDetailRow row) {
    final decoded = jsonDecode(row.detailJson);
    if (decoded is! Map) {
      throw AuthException('Cache UE corrompu.');
    }
    return RecordingUnitMobileDetail.fromApiData(
      Map<String, dynamic>.from(decoded),
    );
  }

  /// Fiche minimale à partir de la liste projet (sans champs de formulaire).
  static RecordingUnitMobileDetail? _minimalFromSummary(
    RecordingUnitItem? summary,
    String resourceId,
  ) {
    if (summary == null) return null;
    final typeId = summary.typeConceptId;
    return RecordingUnitMobileDetail(
      recordingUnit: {
        'resourceId': summary.id.isNotEmpty ? summary.id : resourceId,
        'id': summary.id.isNotEmpty ? summary.id : resourceId,
        'fullIdentifier': summary.displayCode,
        'identifier': summary.identifier,
        if (typeId != null) 'typeConceptId': typeId,
        if (typeId != null)
          'type': {
            'data': {
              'resourceType': 'concepts',
              'resourceId': typeId.toString(),
            },
          },
      },
      fields: const {},
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
