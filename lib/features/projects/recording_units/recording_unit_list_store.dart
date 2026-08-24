import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';

/// Liste des UE d’un projet — pagination à la demande (API + cache SQLite).
///
/// Chaque page lue en ligne est **persistée** dans SQLite pour consultation /
/// recherche hors ligne. On ne télécharge pas toute la liste d’un coup.
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

  /// Nombre d’UE déjà présentes en cache local pour ce projet.
  Future<int> cachedCount(String projectId) =>
      _db.countRecordingUnitsForProject(projectId.trim());

  /// Charge une page pour l’affichage.
  ///
  /// En ligne : API puis enregistrement SQLite de la page.
  /// Hors ligne : pagination sur le cache local uniquement.
  Future<RecordingUnitListResult> loadPage({
    required String projectId,
    required int offset,
    required int limit,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      return RecordingUnitListResult(
        items: const [],
        total: 0,
        offset: 0,
        limit: limit,
      );
    }

    if (await _isOnline) {
      try {
        final page = await _auth.fetchProjectRecordingUnits(
          key,
          offset: offset,
          limit: limit,
        );
        await _persistPage(projectId: key, items: page.items);
        return page;
      } on AuthException {
        return _loadOfflinePage(key, offset: offset, limit: limit);
      }
    }

    return _loadOfflinePage(key, offset: offset, limit: limit);
  }

  /// Persiste une page d’UE dans SQLite (mode hors ligne).
  Future<void> _persistPage({
    required String projectId,
    required List<RecordingUnitItem> items,
  }) async {
    if (items.isEmpty) return;
    try {
      await _db.upsertRecordingUnits(projectId: projectId, items: items);
      if (kDebugMode) {
        final count = await _db.countRecordingUnitsForProject(projectId);
        debugPrint(
          '[Siamois] Cache UE projet $projectId — '
          '+${items.length} (total local $count)',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Siamois] Échec persistance cache UE : $e\n$st');
      }
      // La page reste affichable même si l’écriture cache échoue.
    }
  }

  /// Recherche paginée : filtre SQL sur le cache local (pages déjà chargées).
  Future<RecordingUnitListResult> searchPage({
    required String projectId,
    required String query,
    required int offset,
    required int limit,
  }) async {
    final key = projectId.trim();
    final q = query.trim();
    if (key.isEmpty || q.isEmpty) {
      return loadPage(projectId: key, offset: offset, limit: limit);
    }

    final rows = await _db.searchRecordingUnitsPageForProject(
      projectId: key,
      query: q,
      offset: offset,
      limit: limit,
    );
    final total = await _db.countRecordingUnitsMatchingQuery(
      projectId: key,
      query: q,
    );
    return RecordingUnitListResult(
      items: rows.map(itemFromCacheRow).toList(),
      total: total,
      offset: offset,
      limit: limit,
    );
  }

  /// Télécharge un sous-ensemble d’UE (plafond) et les met en cache.
  Future<List<RecordingUnitItem>> syncFullListFromNetwork(
    String projectId, {
    int maxItems = 2000,
  }) async {
    return _loadAllFromNetwork(projectId.trim(), maxItems: maxItems);
  }

  /// Actualisation : recharge une page depuis l’API (et la met en cache).
  Future<RecordingUnitListResult> refreshFromNetwork({
    required String projectId,
    int offset = 0,
    int limit = 50,
  }) {
    return loadPage(projectId: projectId, offset: offset, limit: limit);
  }

  Future<RecordingUnitListResult> _loadOfflinePage(
    String projectId, {
    required int offset,
    required int limit,
  }) async {
    final rows = await _db.recordingUnitsPageForProject(
      projectId: projectId,
      offset: offset,
      limit: limit,
    );
    final total = await _db.countRecordingUnitsForProject(projectId);
    return RecordingUnitListResult(
      items: rows.map(itemFromCacheRow).toList(),
      total: total,
      offset: offset,
      limit: limit,
    );
  }

  /// Cache SQLite d’abord pour les sélecteurs ; complète via API si besoin (plafonné).
  Future<RecordingUnitPickerLoadResult> loadAllForPicker(
    String projectId, {
    String? excludeRecordingUnitId,
    void Function(List<RecordingUnitItem> items)? onRefreshedFromNetwork,
    int maxItems = 500,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      return const RecordingUnitPickerLoadResult(items: [], fromCache: true);
    }

    final cached = _applyExclude(
      await _allFromCacheCapped(key, maxItems: maxItems),
      excludeRecordingUnitId,
    );

    if (cached.isNotEmpty) {
      if (await _isOnline) {
        _syncAllFromNetwork(
          key,
          excludeRecordingUnitId: excludeRecordingUnitId,
          onDone: onRefreshedFromNetwork,
          maxItems: maxItems,
        );
      }
      return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
    }

    if (await _isOnline) {
      try {
        final fresh = await _loadAllFromNetwork(
          key,
          excludeRecordingUnitId: excludeRecordingUnitId,
          maxItems: maxItems,
        );
        return RecordingUnitPickerLoadResult(items: fresh, fromCache: false);
      } on AuthException {
        return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
      }
    }

    return RecordingUnitPickerLoadResult(items: cached, fromCache: true);
  }

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

  Future<List<RecordingUnitItem>> loadAllFromCacheForProject(
    String projectId, {
    String? excludeRecordingUnitId,
    int maxItems = 2000,
  }) async {
    return _applyExclude(
      await _allFromCacheCapped(projectId.trim(), maxItems: maxItems),
      excludeRecordingUnitId,
    );
  }

  Future<List<RecordingUnitItem>> _allFromCacheCapped(
    String projectId, {
    required int maxItems,
  }) async {
    final rows = await _db.recordingUnitsPageForProject(
      projectId: projectId,
      offset: 0,
      limit: maxItems,
    );
    return rows.map(itemFromCacheRow).toList();
  }

  Future<List<RecordingUnitItem>> _loadAllFromNetwork(
    String projectId, {
    String? excludeRecordingUnitId,
    int maxItems = 2000,
  }) async {
    if (projectId.isEmpty) return const [];

    final all = <RecordingUnitItem>[];
    var offset = 0;
    const limit = 100;

    while (all.length < maxItems) {
      final page = await _auth.fetchProjectRecordingUnits(
        projectId,
        offset: offset,
        limit: limit,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      // Persister page par page (évite de tout perdre en cas d’interruption).
      await _persistPage(projectId: projectId, items: page.items);
      offset += page.items.length;

      if (page.items.length < limit) break;
      if (page.total > limit && offset >= page.total) break;
    }

    final capped = all.length > maxItems ? all.sublist(0, maxItems) : all;
    return _applyExclude(capped, excludeRecordingUnitId);
  }

  void _syncAllFromNetwork(
    String projectId, {
    String? excludeRecordingUnitId,
    void Function(List<RecordingUnitItem> items)? onDone,
    int maxItems = 500,
  }) {
    Future(() async {
      try {
        final fresh = await _loadAllFromNetwork(
          projectId,
          excludeRecordingUnitId: excludeRecordingUnitId,
          maxItems: maxItems,
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

  static RecordingUnitItem itemFromCacheRow(UniteEnregistrement row) {
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
