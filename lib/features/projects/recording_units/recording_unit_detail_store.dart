import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/sync/entity_snapshot_store.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_hierarchy.dart';
import 'recording_unit_list_store.dart';
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
    String? projectId,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant UE invalide.');
    }

    if (RecordingUnitLocalId.isLocalListId(key)) {
      return _loadFromLocal(
        key,
        summary: summary,
        projectId: projectId,
      );
    }

    final canUseApi = await _auth.canUseProjectsApi();
    if (canUseApi) {
      try {
        final fetched = await _auth.fetchRecordingUnitDetail(key);
        final cached = await loadFromCache(key, summary: summary);
        final detail = cached != null
            ? RecordingUnitHierarchy.mergeCachedHierarchy(
                apiDetail: fetched,
                cachedDetail: cached,
              )
            : fetched;
        await _persistDetail(key, detail);
        await EntitySnapshotStore(_db).saveRecordingUnitSnapshot(
          entityId: key,
          serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
          detailApiData: detail.toApiData(),
        );
        return detail;
      } on AuthException {
        return _loadFromLocal(
          key,
          summary: summary,
          projectId: projectId,
        );
      }
    }

    return _loadFromLocal(
      key,
      summary: summary,
      projectId: projectId,
    );
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

  /// Détail depuis SQLite uniquement (sans appel réseau).
  Future<RecordingUnitMobileDetail?> loadFromCache(
    String recordingUnitId, {
    RecordingUnitItem? summary,
    String? projectId,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) return null;

    final row = await _db.recordingUnitDetailRow(key);
    if (row != null) {
      return _parseLocalRow(row);
    }

    return _minimalFromSummary(
      summary ?? await _resolveListItem(key, projectId: projectId),
      key,
    );
  }

  Future<RecordingUnitMobileDetail> _loadFromLocal(
    String resourceId, {
    RecordingUnitItem? summary,
    String? projectId,
  }) async {
    final cached = await loadFromCache(
      resourceId,
      summary: summary,
      projectId: projectId,
    );
    if (cached != null) {
      await _persistDetailIfNeeded(resourceId, cached);
      return cached;
    }

    final snapshot =
        await EntitySnapshotStore(_db).recordingUnitBaseSnapshot(resourceId);
    if (snapshot != null) {
      final detail = RecordingUnitMobileDetail.fromApiData(snapshot);
      await _persistDetail(resourceId, detail);
      return detail;
    }

    final listItem =
        summary ?? await _resolveListItem(resourceId, projectId: projectId);
    final minimal = _minimalFromSummary(listItem, resourceId);
    if (minimal != null) {
      await _persistDetailIfNeeded(resourceId, minimal);
      return minimal;
    }

    final offline = await _auth.isOfflineEnvironment();
    final offlineSession = _auth.isOfflineSession;
    throw AuthException(
      offlineSession
          ? 'Consultation UE indisponible : aucune donnée en cache pour cette unité. '
              'Ouvrez ce projet en ligne au moins une fois pour la synchroniser.'
          : offline
              ? 'Consultation UE indisponible hors ligne. '
                  'Ouvrez cette UE en ligne au moins une fois.'
              : 'Impossible de charger le détail de cette UE. '
                  'Vérifiez votre connexion ou reconnectez-vous.',
    );
  }

  Future<void> _persistDetailIfNeeded(
    String resourceId,
    RecordingUnitMobileDetail detail,
  ) async {
    final existing = await _db.recordingUnitDetailRow(resourceId);
    if (existing != null) return;
    await _persistDetail(resourceId, detail);
  }

  Future<RecordingUnitItem?> _resolveListItem(
    String recordingUnitId, {
    String? projectId,
    RecordingUnitItem? summary,
  }) async {
    if (summary != null) return summary;

    final key = recordingUnitId.trim();
    if (key.isEmpty) return null;

    final direct = await _db.recordingUnitListRow(key);
    if (direct != null) {
      return RecordingUnitListStore.itemFromCacheRow(direct);
    }

    final projectKey = projectId?.trim();
    if (projectKey == null || projectKey.isEmpty) return null;

    final rows = await _db.recordingUnitsForProject(projectKey);
    for (final row in rows) {
      if (row.resourceId == key ||
          row.displayCode == key ||
          row.identifier == key) {
        return RecordingUnitListStore.itemFromCacheRow(row);
      }
    }
    return null;
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
    final resolvedId =
        summary.id.trim().isNotEmpty ? summary.id.trim() : resourceId;
    return RecordingUnitMobileDetail(
      recordingUnit: {
        'resourceId': resolvedId,
        'id': resolvedId,
        'fullIdentifier': summary.displayCode,
        'identifier': summary.identifier,
        if (typeId != null) 'typeConceptId': typeId,
        if (summary.typeLabel != null && summary.typeLabel!.trim().isNotEmpty)
          'type': {
            'data': {
              'resourceType': 'concepts',
              'resourceId': typeId?.toString(),
              'label': summary.typeLabel,
              'displayLabel': summary.typeLabel,
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
