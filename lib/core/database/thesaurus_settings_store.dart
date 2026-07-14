import 'app_database.dart';
import '../../features/settings/thesaurus_settings_scope.dart';

/// Métadonnées thésaurus en cache local.
class ThesaurusSettingsSnapshot {
  const ThesaurusSettingsSnapshot({
    this.thesaurusUrl,
    this.thesaurusLabel,
    this.userConfigured = false,
    this.serverSyncedAt,
  });

  final String? thesaurusUrl;
  final String? thesaurusLabel;
  final bool userConfigured;
  final DateTime? serverSyncedAt;
}

/// Cache local de l’URL du thésaurus par organisation et périmètre.
class ThesaurusSettingsStore {
  ThesaurusSettingsStore(this._db);

  final AppDatabase _db;

  Future<ThesaurusSettingsSnapshot> loadSnapshot({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    final row = await _db.findThesaurusSetting(
      organisationId: organisationId,
      scope: scope.storageKey,
    );
    if (row == null) {
      return const ThesaurusSettingsSnapshot();
    }
    final url = row.thesaurusUrl.trim();
    final label = row.thesaurusLabel?.trim();
    return ThesaurusSettingsSnapshot(
      thesaurusUrl: url.isEmpty ? null : url,
      thesaurusLabel: label?.isNotEmpty == true ? label : null,
      userConfigured: row.userConfigured,
      serverSyncedAt: row.serverSyncedAt,
    );
  }

  Future<String?> loadUrl({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    return (await loadSnapshot(
      organisationId: organisationId,
      scope: scope,
    ))
        .thesaurusUrl;
  }

  Future<DateTime?> loadServerSyncedAt({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    return (await loadSnapshot(
      organisationId: organisationId,
      scope: scope,
    ))
        .serverSyncedAt;
  }

  Future<void> saveLocal({
    required int organisationId,
    required ThesaurusSettingsScope scope,
    required String thesaurusUrl,
    DateTime? serverSyncedAt,
    String? thesaurusLabel,
    bool? userConfigured,
  }) {
    return _db.upsertThesaurusSetting(
      organisationId: organisationId,
      scope: scope.storageKey,
      thesaurusUrl: thesaurusUrl,
      serverSyncedAt: serverSyncedAt,
      thesaurusLabel: thesaurusLabel,
      userConfigured: userConfigured,
    );
  }
}
