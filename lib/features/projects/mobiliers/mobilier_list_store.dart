import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../recording_units/recording_unit_detail_models.dart';

/// Liste paginée des mobiliers d’une UE (API en ligne, SQLite hors ligne).
class MobilierListStore {
  MobilierListStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get isOnline => _auth.canUseProjectsApi();

  Future<bool> get _isOnline => isOnline;

  Future<MobilierListResult> loadPage({
    required String recordingUnitId,
    required int offset,
    required int limit,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      return const MobilierListResult(
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
        final page = await _auth.fetchRecordingUnitMobiliers(
          key,
          offset: offset,
          limit: limit,
        );
        for (final item in page.items) {
          await _db.upsertMobilier(
            item: item,
            uniteEnregistrementId: key,
          );
        }
        return page;
      } on AuthException {
        return _loadOffline(key, offset: offset, limit: limit);
      }
    }

    return _loadOffline(key, offset: offset, limit: limit);
  }

  void scheduleFullListSyncFromNetwork(String recordingUnitId) {
    final key = recordingUnitId.trim();
    if (key.isEmpty) return;
    Future(() async {
      try {
        await _loadAllFromNetwork(key);
      } catch (_) {
        // Le cache affiché reste valide.
      }
    });
  }

  /// Actualisation explicite : liste complète depuis l’API, remplacement SQLite, 1re page.
  Future<MobilierListResult> refreshFromNetwork({
    required String recordingUnitId,
    int offset = 0,
    int limit = 20,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      return const MobilierListResult(
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

    return _loadOffline(key, offset: offset, limit: limit);
  }

  Future<void> _loadAllFromNetwork(String recordingUnitId) async {
    final all = <MobilierItem>[];
    var offset = 0;
    const limit = 100;

    while (true) {
      final page = await _auth.fetchRecordingUnitMobiliers(
        recordingUnitId,
        offset: offset,
        limit: limit,
      );
      all.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;
      offset += page.items.length;
    }

    await _db.replaceMobiliersForRecordingUnit(
      uniteEnregistrementId: recordingUnitId,
      items: all,
    );
  }

  Future<MobilierListResult> _loadOffline(
    String recordingUnitId, {
    required int offset,
    required int limit,
  }) async {
    final rows = await _db.mobiliersForRecordingUnit(recordingUnitId);
    final all = rows.map(_itemFromRow).toList();
    final slice = all.skip(offset).take(limit).toList();
    return MobilierListResult(
      items: slice,
      total: all.length,
      offset: offset,
      limit: limit,
    );
  }

  static MobilierItem _itemFromRow(MobilierCache row) {
    return MobilierItem(
      id: row.resourceId,
      displayCode: row.displayCode,
      typeLabel: row.typeLabel,
      collectionDate: row.collectionDate,
    );
  }

  Future<void> upsertLocal({
    required MobilierItem item,
    required String recordingUnitId,
  }) async {
    await _db.upsertMobilier(
      item: item,
      uniteEnregistrementId: recordingUnitId,
    );
  }

  Future<void> removeLocal(String resourceId) async {
    await _db.deleteMobilierByResourceId(resourceId);
  }
}
