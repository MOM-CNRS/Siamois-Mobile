import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';

/// Liste des UE d’un projet.
///
/// En ligne : pagination API pour l’affichage + synchronisation intégrale en arrière-plan
/// dans SQLite. Hors ligne : pagination sur le cache local.
class RecordingUnitListStore {
  RecordingUnitListStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// `true` si la liste peut être chargée ou rafraîchie depuis l’API.
  Future<bool> get isOnline => _auth.canUseProjectsApi();

  Future<bool> get _isOnline => isOnline;

  /// Charge une page pour l’affichage (API en ligne, cache SQLite hors ligne).
  Future<RecordingUnitListResult> loadPage({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      return const RecordingUnitListResult(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      );
    }

    if (await _isOnline) {
      try {
        if (offset == 0) {
          scheduleFullListSyncFromNetwork(key);
        }
        final page = await _auth.fetchProjectRecordingUnits(
          key,
          offset: offset,
          limit: limit,
        );
        for (final item in page.items) {
          await _db.upsertRecordingUnit(
            item: item,
            projectId: key,
            typeConceptId: item.typeConceptId,
          );
        }
        return page;
      } on AuthException {
        return _loadOfflinePage(key, offset: offset, limit: limit);
      }
    }

    return _loadOfflinePage(key, offset: offset, limit: limit);
  }

  /// Lance en arrière-plan le téléchargement de toutes les UE vers SQLite.
  void scheduleFullListSyncFromNetwork(String projectId) {
    final key = projectId.trim();
    if (key.isEmpty) return;
    _syncAllFromNetwork(key);
  }

  /// Télécharge toutes les UE du projet (pagination API) et remplace le cache local.
  Future<List<RecordingUnitItem>> syncFullListFromNetwork(
    String projectId,
  ) async {
    return _loadAllFromNetwork(projectId.trim());
  }

  /// Actualisation explicite : liste complète depuis l’API, remplacement SQLite, 1re page.
  Future<RecordingUnitListResult> refreshFromNetwork({
    required String projectId,
    int offset = 0,
    int limit = 20,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      return const RecordingUnitListResult(
        items: [],
        total: 0,
        offset: 0,
        limit: 20,
      );
    }

    if (await _isOnline) {
      try {
        await _loadAllFromNetwork(key);
      } on AuthException {
        // Affiche le cache local si l’API échoue.
      }
    }

    return _loadOfflinePage(key, offset: offset, limit: limit);
  }

  Future<RecordingUnitListResult> _loadOfflinePage(
    String projectId, {
    required int offset,
    required int limit,
  }) async {
    final all = await _allFromCache(projectId);
    final slice = all.skip(offset).take(limit).toList();
    return RecordingUnitListResult(
      items: slice,
      total: all.length,
      offset: offset,
      limit: limit,
    );
  }

  /// Toutes les UE du projet pour le sélecteur multiple : **cache SQLite d’abord**.
  ///
  /// Si le cache contient des lignes, elles sont renvoyées immédiatement (hors ligne
  /// ou en ligne). Sinon, tentative de chargement API pour remplir le cache.
  Future<RecordingUnitPickerLoadResult> loadAllForPicker(
    String projectId, {
    String? excludeRecordingUnitId,
    void Function(List<RecordingUnitItem> items)? onRefreshedFromNetwork,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      return const RecordingUnitPickerLoadResult(items: [], fromCache: true);
    }

    final cached = _applyExclude(
      await _allFromCache(key),
      excludeRecordingUnitId,
    );

    if (cached.isNotEmpty) {
      if (await _isOnline) {
        _syncAllFromNetwork(
          key,
          excludeRecordingUnitId: excludeRecordingUnitId,
          onDone: onRefreshedFromNetwork,
        );
      }
      return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
    }

    if (await _isOnline) {
      try {
        final fresh = await _loadAllFromNetwork(
          key,
          excludeRecordingUnitId: excludeRecordingUnitId,
        );
        return RecordingUnitPickerLoadResult(items: fresh, fromCache: false);
      } on AuthException {
        return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
      }
    }

    return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
  }

  /// Compatibilité : renvoie uniquement la liste.
  Future<List<RecordingUnitItem>> loadAllForProject(
    String projectId, {
    String? excludeRecordingUnitId,
    void Function(List<RecordingUnitItem> items)? onRefreshedFromNetwork,
  }) async {
    final result = await loadAllForPicker(
      projectId,
      excludeRecordingUnitId: excludeRecordingUnitId,
      onRefreshedFromNetwork: onRefreshedFromNetwork,
    );
    return result.items;
  }

  /// Lecture directe du cache local (table `unites_enregistrement`).
  Future<List<RecordingUnitItem>> loadAllFromCacheForProject(
    String projectId, {
    String? excludeRecordingUnitId,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) return const [];
    return _applyExclude(
      await _allFromCache(key),
      excludeRecordingUnitId,
    );
  }

  Future<List<RecordingUnitItem>> _allFromCache(String projectId) async {
    final rows = await _db.recordingUnitsForProject(projectId);
    final items = rows.map(_itemFromRow).toList();
    return _enrichHierarchyFromDetails(items);
  }

  Future<List<RecordingUnitItem>> _enrichHierarchyFromDetails(
    List<RecordingUnitItem> items,
  ) async {
    final out = <RecordingUnitItem>[];
    for (final item in items) {
      if (item.parentIds.isNotEmpty || item.childIds.isNotEmpty) {
        out.add(item);
        continue;
      }
      final row = await _db.recordingUnitDetailRow(item.id);
      if (row == null) {
        out.add(item);
        continue;
      }
      try {
        final decoded = jsonDecode(row.detailJson);
        if (decoded is! Map) {
          out.add(item);
          continue;
        }
        final map = Map<String, dynamic>.from(decoded);
        final ruRaw = map['recordingUnit'];
        if (ruRaw is! Map) {
          out.add(item);
          continue;
        }
        out.add(
          item.enrichHierarchyFrom(Map<String, dynamic>.from(ruRaw)),
        );
      } catch (_) {
        out.add(item);
      }
    }
    return out;
  }

  Future<List<RecordingUnitItem>> _loadAllFromNetwork(
    String projectId, {
    String? excludeRecordingUnitId,
  }) async {
    if (projectId.isEmpty) return const [];

    final all = <RecordingUnitItem>[];
    var offset = 0;
    const limit = 100;

    while (true) {
      final page = await _auth.fetchProjectRecordingUnits(
        projectId,
        offset: offset,
        limit: limit,
      );
      all.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;
      offset += page.items.length;
    }

    await _db.replaceRecordingUnitsForProject(
      projectId: projectId,
      items: all,
      typeConceptIdsByResourceId: {
        for (final u in all)
          if (u.typeConceptId != null) u.id: u.typeConceptId!,
      },
    );

    return _applyExclude(all, excludeRecordingUnitId);
  }

  void _syncAllFromNetwork(
    String projectId, {
    String? excludeRecordingUnitId,
    void Function(List<RecordingUnitItem> items)? onDone,
  }) {
    Future(() async {
      try {
        final fresh = await _loadAllFromNetwork(
          projectId,
          excludeRecordingUnitId: excludeRecordingUnitId,
        );
        onDone?.call(fresh);
      } catch (_) {
        // Le cache affiché reste valide.
      }
    });
  }

  static List<RecordingUnitItem> _applyExclude(
    List<RecordingUnitItem> items,
    String? excludeRecordingUnitId,
  ) {
    final exclude = excludeRecordingUnitId?.trim();
    if (exclude == null || exclude.isEmpty) return items;

    return items
        .where(
          (u) =>
              u.id != exclude &&
              u.displayCode != exclude &&
              (u.identifier == null || u.identifier != exclude),
        )
        .toList();
  }

  static RecordingUnitItem _itemFromRow(UniteEnregistrement row) {
    return RecordingUnitItem(
      id: row.resourceId,
      displayCode: row.displayCode,
      identifier: row.identifier,
      typeLabel: row.typeLabel,
      typeConceptId: row.typeConceptId,
      placeLabel: row.placeLabel,
      openingDate: row.openingDate,
      closingDate: row.closingDate,
      matrixColor: row.matrixColor,
      specimenCount: row.specimenCount,
      stratigraphicCount: row.stratigraphicCount,
      parentIds: AppDatabase.decodeParentIdsForRecordingUnit(row.parentIdsJson),
    );
  }

  Future<void> upsertLocal({
    required RecordingUnitItem item,
    required String projectId,
    int? typeConceptId,
  }) async {
    await _db.upsertRecordingUnit(
      item: item,
      projectId: projectId,
      typeConceptId: typeConceptId,
    );
  }

  Future<void> removeLocal(String resourceId) async {
    await _db.deleteRecordingUnitByResourceId(resourceId);
  }
}

/// Résultat du chargement pour le sélecteur UE (cache vs réseau).
class RecordingUnitPickerLoadResult {
  const RecordingUnitPickerLoadResult({
    required this.items,
    required this.fromCache,
  });

  final List<RecordingUnitItem> items;
  final bool fromCache;
}
