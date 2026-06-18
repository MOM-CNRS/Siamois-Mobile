import 'app_database.dart';
import '../../features/settings/thesaurus_settings_scope.dart';

/// Cache local de l’URL du thésaurus par organisation et périmètre.
class ThesaurusSettingsStore {
  ThesaurusSettingsStore(this._db);

  final AppDatabase _db;

  Future<String?> loadUrl({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    final row = await _db.findThesaurusSetting(
      organisationId: organisationId,
      scope: scope.storageKey,
    );
    final url = row?.thesaurusUrl.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Future<DateTime?> loadServerSyncedAt({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    return (await _db.findThesaurusSetting(
      organisationId: organisationId,
      scope: scope.storageKey,
    ))
        ?.serverSyncedAt;
  }

  Future<void> saveLocal({
    required int organisationId,
    required ThesaurusSettingsScope scope,
    required String thesaurusUrl,
    DateTime? serverSyncedAt,
  }) {
    return _db.upsertThesaurusSetting(
      organisationId: organisationId,
      scope: scope.storageKey,
      thesaurusUrl: thesaurusUrl,
      serverSyncedAt: serverSyncedAt,
    );
  }
}
