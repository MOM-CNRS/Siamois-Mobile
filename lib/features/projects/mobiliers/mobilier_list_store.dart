import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../auth/auth_repository.dart';
import '../recording_units/recording_unit_detail_models.dart';

/// Liste paginée des mobiliers d’une UE (API en ligne, SQLite hors ligne).
class MobilierListStore {
  MobilierListStore({
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
        final page = await _auth.fetchRecordingUnitMobiliers(
          key,
          offset: offset,
          limit: limit,
        );
        if (offset == 0) {
          await _db.replaceMobiliersForRecordingUnit(
            uniteEnregistrementId: key,
            items: page.items,
          );
        } else {
          for (final item in page.items) {
            await _db.upsertMobilier(
              item: item,
              uniteEnregistrementId: key,
            );
          }
        }
        return page;
      } on AuthException {
        return _loadOffline(key, offset: offset, limit: limit);
      }
    }

    return _loadOffline(key, offset: offset, limit: limit);
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
