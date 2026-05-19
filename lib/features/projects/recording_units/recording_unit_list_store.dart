import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';

/// Liste paginée des UE d’un projet (API en ligne, SQLite hors ligne).
class RecordingUnitListStore {
  RecordingUnitListStore({
    required AuthRepository auth,
    required AppDatabase db,
    ConnectivityService? connectivity,
  })  : _auth = auth,
        _db = db,
        _connectivity = connectivity ?? auth.connectivity;

  final AuthRepository _auth;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<bool> get isOnline async {
    final base = _auth.lastUsedBaseUrl;
    if (base.isEmpty) return false;
    return _connectivity.isOnline(base);
  }

  Future<bool> get _isOnline => isOnline;

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
        final page = await _auth.fetchProjectRecordingUnits(
          key,
          offset: offset,
          limit: limit,
        );
        if (offset == 0) {
          await _db.replaceRecordingUnitsForProject(
            projectId: key,
            items: page.items,
          );
        } else {
          for (final item in page.items) {
            await _db.upsertRecordingUnit(item: item, projectId: key);
          }
        }
        return page;
      } on AuthException {
        return _loadOfflinePage(key, offset: offset, limit: limit);
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
    return rows.map(_itemFromRow).toList();
  }

  Future<List<RecordingUnitItem>> _loadAllFromNetwork(
    String projectId, {
    String? excludeRecordingUnitId,
  }) async {
    final all = <RecordingUnitItem>[];
    var offset = 0;
    const limit = 100;

    while (true) {
      final page = await _auth.fetchProjectRecordingUnits(
        projectId,
        offset: offset,
        limit: limit,
      );
      if (offset == 0) {
        await _db.replaceRecordingUnitsForProject(
          projectId: projectId,
          items: page.items,
        );
      } else {
        for (final item in page.items) {
          await _db.upsertRecordingUnit(item: item, projectId: projectId);
        }
      }
      all.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;
      offset += page.items.length;
    }

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
      placeLabel: row.placeLabel,
      openingDate: row.openingDate,
      closingDate: row.closingDate,
      matrixColor: row.matrixColor,
      specimenCount: row.specimenCount,
      stratigraphicCount: row.stratigraphicCount,
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
