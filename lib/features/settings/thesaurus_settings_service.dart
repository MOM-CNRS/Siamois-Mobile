import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../core/database/thesaurus_settings_store.dart';
import '../auth/auth_repository.dart';
import 'thesaurus_settings_scope.dart';
import 'user_thesaurus_info.dart';
import '../projects/vocabulary_models.dart';

/// Cache thésaurus + vocabulaires (bootstrap / synchronisation).
class ThesaurusSettingsService {
  ThesaurusSettingsService({
    required AuthRepository auth,
    required AppDatabase database,
  })  : _auth = auth,
        _store = ThesaurusSettingsStore(database),
        _db = database;

  final AuthRepository _auth;
  final ThesaurusSettingsStore _store;
  final AppDatabase _db;

  static const _vocabularyTtlDays = 1;

  /// Pendant le bootstrap (post-login / rechargement cache) : récupère l’URL
  /// serveur, la met en cache locale et recharge les vocabulaires associés.
  Future<bool> bootstrapSyncForOrganisation({
    required int organisationId,
    bool refreshVocabularies = true,
  }) async {
    if (!await _auth.canUseProjectsApi()) return false;

    final remote = await _auth.fetchUserThesaurusInfo(
      organizationId: organisationId,
    );
    final trimmed = remote.thesaurusUrl.trim();
    if (trimmed.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Thesaurus] Bootstrap org $organisationId — '
          'pas de thésaurus serveur (GET /users/me/thesaurus vide).',
        );
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        '[Siamois Thesaurus] Bootstrap org $organisationId — '
        'URL serveur: $trimmed'
        '${remote.userConfigured ? ' (Personnel)' : ' (Organisation)'}'
        '${refreshVocabularies ? '' : ' — vocabulaires différés'}',
      );
    }

    await _persistThesaurusInfo(
      organisationId: organisationId,
      scope: ThesaurusSettingsScope.user,
      info: remote,
      serverSyncedAt: DateTime.now(),
    );

    if (!refreshVocabularies) return true;

    try {
      await _refreshVocabularies(organisationId);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Thesaurus] Bootstrap org $organisationId — '
          'URL en cache, vocabulaires non chargés: ${e.message}',
        );
      }
    }
    return true;
  }

  /// Met en cache les vocabulaires si absents ou expirés (utilisés par les formulaires).
  Future<void> ensureVocabulariesCached(int organisationId) async {
    if (!await _auth.canUseProjectsApi()) return;
    if (await _hasValidVocabularyCache(organisationId)) return;

    if (kDebugMode) {
      debugPrint(
        '[Siamois Thesaurus] Cache vocabulaires absent ou expiré '
        '(org $organisationId) — téléchargement.',
      );
    }
    await _refreshVocabularies(organisationId);
  }

  Future<bool> _hasValidVocabularyCache(int organisationId) async {
    final row = await _db.findValidForm(
      organisationId: organisationId,
      type: FormCacheType.vocabulaire,
    );
    return row != null;
  }

  Future<void> _persistThesaurusInfo({
    required int organisationId,
    required ThesaurusSettingsScope scope,
    required UserThesaurusInfo info,
    DateTime? serverSyncedAt,
  }) {
    return _store.saveLocal(
      organisationId: organisationId,
      scope: scope,
      thesaurusUrl: info.thesaurusUrl,
      thesaurusLabel: info.label,
      userConfigured: info.userConfigured,
      serverSyncedAt: serverSyncedAt,
    );
  }

  Future<void> _refreshVocabularies(int organisationId) async {
    await _db.clearFormCache(
      organisationId: organisationId,
      type: FormCacheType.vocabulaire,
    );
    final body = await _auth.fetchVocabulariesRaw(
      organizationId: organisationId,
    );
    await _db.replaceForm(
      organisationId: organisationId,
      type: FormCacheType.vocabulaire,
      contenuJson: jsonEncode(body),
      ttlDays: _vocabularyTtlDays,
    );
    await _logLoadedConceptStats(
      organisationId: organisationId,
      body: body,
      source: 'Cache vocabulaires',
    );
  }

  Future<void> _logLoadedConceptStats({
    required int organisationId,
    required Map<String, dynamic> body,
    required String source,
  }) async {
    if (!kDebugMode) return;

    final diagnostic = VocabularyDiagnostic.fromBody(body);
    final snapshot = await _store.loadSnapshot(
      organisationId: organisationId,
      scope: ThesaurusSettingsScope.user,
    );
    final url = snapshot.thesaurusUrl ?? '(aucune URL en cache)';
    final label = snapshot.thesaurusLabel;

    debugPrint(
      '[Siamois Thesaurus] $source — org $organisationId'
      '${label != null ? ' — $label' : ''}\n'
      '  Thésaurus: $url\n'
      '  ${diagnostic.summary}',
    );
    for (final line in diagnostic.detailLines) {
      debugPrint('[Siamois Thesaurus]   $line');
    }
  }
}
