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
    final localUrl = await _store.loadUrl(
      organisationId: organisationId,
      scope: scope,
    );
    var serverSyncedAt = await _store.loadServerSyncedAt(
      organisationId: organisationId,
      scope: scope,
    );

    final online = await _auth.canUseProjectsApi();
    if (online) {
      try {
        final remote = await _auth.fetchUserThesaurusUrl(
          organizationId: organisationId,
        );
        final trimmed = remote?.trim() ?? '';
        if (trimmed.isNotEmpty) {
          final localTrimmed = localUrl?.trim() ?? '';
          if (localTrimmed != trimmed || serverSyncedAt == null) {
            await _store.saveLocal(
              organisationId: organisationId,
              scope: scope,
              thesaurusUrl: trimmed,
              serverSyncedAt: DateTime.now(),
            );
            serverSyncedAt = DateTime.now();
          }
          return ThesaurusSettingsState(
            thesaurusUrl: trimmed,
            serverSyncedAt: serverSyncedAt,
            pendingServerSync: false,
          );
        }
      } on AuthException {
        // Hors ligne ou erreur réseau : afficher le cache local.
      }
    }

    final url = localUrl ?? '';
    return ThesaurusSettingsState(
      thesaurusUrl: url,
      serverSyncedAt: serverSyncedAt,
      pendingServerSync:
          url.isNotEmpty && serverSyncedAt == null && online,
    );
  }

  /// Pendant le bootstrap (post-login / rechargement cache) : récupère l’URL
  /// serveur, la met en cache locale et recharge les vocabulaires associés.
  Future<bool> bootstrapSyncForOrganisation({
    required int organisationId,
    bool refreshVocabularies = true,
  }) async {
    if (!await _auth.canUseProjectsApi()) return false;

    final remote = await _auth.fetchUserThesaurusUrl(
      organizationId: organisationId,
    );
    final trimmed = remote?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Thesaurus] Bootstrap org $organisationId — '
          'pas de thésaurus serveur.',
        );
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        '[Siamois Thesaurus] Bootstrap org $organisationId — '
        'mise en cache de l’URL serveur.',
      );
    }

    await _store.saveLocal(
      organisationId: organisationId,
      scope: ThesaurusSettingsScope.user,
      thesaurusUrl: trimmed,
      serverSyncedAt: DateTime.now(),
    );

    if (refreshVocabularies) {
      await _refreshVocabularies(organisationId);
    }
    return true;
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
      return;
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
      final remoteUrl =
          (await _auth.fetchUserThesaurusUrl(organizationId: organisationId))
                  ?.trim() ??
              '';
      final serverAlreadyConfigured =
          remoteUrl.isNotEmpty && remoteUrl == trimmed;
      var vocabulariesRefreshed = false;

      if (serverAlreadyConfigured) {
        if (kDebugMode) {
          debugPrint(
            '[Siamois Thesaurus] URL déjà configurée sur le serveur — '
            'rechargement des concepts.',
          );
        }
        onProgress?.call(30);
      } else {
        try {
          await _putThesaurusConfig(
            organisationId: organisationId,
            thesaurusUrl: trimmed,
            onProgress: onProgress,
          );
        } on AuthException catch (e) {
          if (_isThesaurusUnchanged(e)) {
            if (kDebugMode) {
              debugPrint(
                '[Siamois Thesaurus] Configuration inchangée — '
                'rechargement des concepts.',
              );
            }
          } else if (_isThesaurusEndpointUnavailable(e)) {
            try {
              onProgress?.call(50);
              await _refreshVocabularies(organisationId);
              vocabulariesRefreshed = true;
            } on AuthException {
              throw const FormatException(_localOnlyMessage);
            }
          } else {
            rethrow;
          }
        }
      }

      if (!vocabulariesRefreshed) {
        onProgress?.call(85);
        await _refreshVocabularies(organisationId);
      }
      onProgress?.call(100);

      await _store.saveLocal(
        organisationId: organisationId,
        scope: scope,
        thesaurusUrl: trimmed,
        serverSyncedAt: DateTime.now(),
      );
    } on FormatException {
      rethrow;
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

  bool _isThesaurusUnchanged(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('unchanged') || msg.contains('inchang');
  }

  bool _isThesaurusEndpointUnavailable(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('code 404') || msg.contains('code 501')) return true;
    if (RegExp(r'code 30\d').hasMatch(msg)) return true;
    return msg.contains('endpoint thésaurus indisponible');
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
