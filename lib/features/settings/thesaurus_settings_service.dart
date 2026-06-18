import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../core/database/thesaurus_settings_store.dart';
import '../auth/auth_repository.dart';
import 'thesaurus_settings_scope.dart';

/// Configuration thésaurus (utilisateur ou organisation) : cache + serveur.
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
  static const _localOnlyMessage =
      'URL enregistrée localement. '
      'Le serveur ne propose pas encore cette configuration depuis l’application mobile.';
  static const _timeoutMessage =
      'URL enregistrée localement. '
      'La synchronisation serveur a expiré ; réessayez plus tard.';

  Future<ThesaurusSettingsState> load({
    required int organisationId,
    required ThesaurusSettingsScope scope,
  }) async {
    var url = await _store.loadUrl(
      organisationId: organisationId,
      scope: scope,
    );
    final serverSyncedAt = await _store.loadServerSyncedAt(
      organisationId: organisationId,
      scope: scope,
    );

    if ((url == null || url.isEmpty) && await _auth.canUseProjectsApi()) {
      final remote = await _auth.fetchUserThesaurusUrl(
        organizationId: organisationId,
      );
      if (remote != null && remote.trim().isNotEmpty) {
        url = remote.trim();
        await _store.saveLocal(
          organisationId: organisationId,
          scope: scope,
          thesaurusUrl: url,
          serverSyncedAt: DateTime.now(),
        );
      }
    }

    return ThesaurusSettingsState(
      thesaurusUrl: url ?? '',
      serverSyncedAt: serverSyncedAt,
      pendingServerSync: url != null &&
          url.isNotEmpty &&
          serverSyncedAt == null &&
          await _auth.canUseProjectsApi(),
    );
  }

  /// Valide l’URL et l’enregistre en base locale (rapide, sans appel serveur).
  Future<void> validateAndSaveLocal({
    required int organisationId,
    required ThesaurusSettingsScope scope,
    required String thesaurusUrl,
  }) async {
    final trimmed = thesaurusUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Aucun thésaurus n’a été renseigné.');
    }

    final previous = await _store.loadUrl(
      organisationId: organisationId,
      scope: scope,
    );
    final serverSyncedAt = await _store.loadServerSyncedAt(
      organisationId: organisationId,
      scope: scope,
    );
    final unchanged = previous != null && previous.trim() == trimmed;
    final pendingServerSync =
        unchanged && serverSyncedAt == null && trimmed.isNotEmpty;

    if (unchanged && !pendingServerSync) {
      throw const FormatException(
        'La configuration du thésaurus n’a pas été modifiée.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[Siamois Thesaurus] Cache local ${scope.storageKey} org $organisationId'
        '${pendingServerSync ? ' (nouvelle tentative serveur)' : ''}',
      );
    }

    if (!unchanged) {
      await _store.saveLocal(
        organisationId: organisationId,
        scope: scope,
        thesaurusUrl: trimmed,
        serverSyncedAt: null,
      );
    }
  }

  /// Envoie la configuration au serveur et rafraîchit les vocabulaires.
  Future<void> syncToServer({
    required int organisationId,
    required ThesaurusSettingsScope scope,
    required String thesaurusUrl,
    void Function(int progressPercent)? onProgress,
  }) async {
    final trimmed = thesaurusUrl.trim();
    if (trimmed.isEmpty) return;

    if (!await _auth.canUseProjectsApi()) {
      if (kDebugMode) {
        debugPrint('[Siamois Thesaurus] Hors ligne — pas de sync serveur.');
      }
      return;
    }

    onProgress?.call(0);
    if (kDebugMode) {
      debugPrint('[Siamois Thesaurus] Synchronisation serveur…');
    }

    try {
      await _putThesaurusConfig(
        organisationId: organisationId,
        thesaurusUrl: trimmed,
        onProgress: onProgress,
      );
      onProgress?.call(85);

      await _refreshVocabularies(organisationId);
      onProgress?.call(100);

      await _store.saveLocal(
        organisationId: organisationId,
        scope: scope,
        thesaurusUrl: trimmed,
        serverSyncedAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      if (_isThesaurusEndpointUnavailable(e)) {
        throw const FormatException(_localOnlyMessage);
      }
      rethrow;
    } on TimeoutException {
      throw const FormatException(_timeoutMessage);
    }
  }

  Future<void> _putThesaurusConfig({
    required int organisationId,
    required String thesaurusUrl,
    void Function(int progressPercent)? onProgress,
  }) async {
    await _auth
        .saveUserThesaurusConfig(
          organizationId: organisationId,
          thesaurusUrl: thesaurusUrl,
          onUploadProgress: (sent, total) {
            if (total <= 0) return;
            final pct = ((sent / total) * 30).round().clamp(0, 30);
            onProgress?.call(pct);
          },
        )
        .timeout(const Duration(seconds: 95));
  }

  bool _isThesaurusEndpointUnavailable(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('code 404') || msg.contains('code 501')) return true;
    if (RegExp(r'code 30\d').hasMatch(msg)) return true;
    if (msg.contains('endpoint thésaurus indisponible')) return true;
    if (msg.contains('erreur réseau')) return true;
    if (msg.contains('receive timeout') || msg.contains('connection timeout')) {
      return true;
    }
    return false;
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
  }
}

class ThesaurusSettingsState {
  const ThesaurusSettingsState({
    required this.thesaurusUrl,
    this.serverSyncedAt,
    this.pendingServerSync = false,
  });

  final String thesaurusUrl;
  final DateTime? serverSyncedAt;
  final bool pendingServerSync;
}
