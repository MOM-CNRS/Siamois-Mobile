import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/auth/auth_models.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/projects/documents/document_tmp_models.dart';
import '../../features/projects/documents/document_tmp_store.dart';
import '../../features/projects/documents/document_upload_sync.dart';
import 'outbox_store.dart';
import 'outbox_sync_engine.dart';
import '../../features/projects/form/person_directory_store.dart';
import '../../features/projects/form/spatial_unit_store.dart';
import '../../features/projects/form/person_option.dart';
import '../../features/projects/project_models.dart';
import '../../features/projects/vocabulary_models.dart';
import '../../features/settings/thesaurus_settings_scope.dart';
import '../../features/settings/thesaurus_settings_service.dart';
import '../database/app_database.dart';
import '../database/thesaurus_settings_store.dart';
import '../database/tables.dart';
import '../network/connectivity_service.dart';
import 'sync_action_models.dart';
import 'sync_queue_models.dart';
import 'sync_progress.dart';

/// Pipeline post-login : auth locale → vocabulaires → formulaire → projets.
class SyncOrchestrator {
  SyncOrchestrator({
    required AuthRepository auth,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _auth = auth,
        _db = db,
        _connectivity = connectivity;

  final AuthRepository _auth;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  final _controller = StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _controller.stream;

  static const _vocabularyTtlDays = 1;
  static const _projectFormTtlDays = 1;

  void _emit(SyncProgress progress) {
    if (!_controller.isClosed) {
      _controller.add(progress);
    }
  }

  void _log(List<String> logs, String line) {
    logs.add('[${DateTime.now().toLocal().toString().substring(11, 19)}] $line');
    if (kDebugMode) {
      debugPrint('[Siamois Sync] $line');
    }
  }

  /// Cache valide, sinon dernière version (TTL expiré) pour le mode hors ligne.
  Future<Form?> _cachedForm({
    required int organisationId,
    required String type,
  }) async {
    final valid = await _db.findValidForm(
      organisationId: organisationId,
      type: type,
    );
    if (valid != null) return valid;
    return _db.findLatestForm(
      organisationId: organisationId,
      type: type,
    );
  }

  /// `true` si les données de référence locales (vocabulaires) sont absentes.
  Future<bool> isLocalCacheEmpty() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return false;

    final vocabulary = await _cachedForm(
      organisationId: orgId,
      type: FormCacheType.vocabulaire,
    );
    return vocabulary == null;
  }

  /// Connexion en ligne avec cache vide → rechargement automatique requis.
  Future<bool> shouldAutoLoadCacheOnLogin() async {
    if (!await _auth.canUseProjectsApi()) return false;
    return isLocalCacheEmpty();
  }

  Future<void> runBootstrap({
    required bool cameFromOnlineLogin,
    bool queueOnly = false,
    bool cacheOnly = false,
  }) async {
    final logs = <String>[];
    final stepCount = SyncProgress.stepLabels.length;

    try {
      final baseUrl = _auth.lastUsedBaseUrl;
      final online = baseUrl.isNotEmpty && await _connectivity.isOnline(baseUrl);

      final outbox = OutboxStore(_db);
      final pendingActions = online && !cacheOnly
          ? await outbox.pendingActions()
          : const <SyncActionEntry>[];
      final pendingDocs = online && !cacheOnly
          ? await DocumentTmpStore(db: _db, auth: _auth).pendingUploads()
          : const <DocumentTmpEntry>[];
      final queueTotal = pendingActions.length + pendingDocs.length;
      final bootstrapSteps =
          queueOnly ? 0 : SyncProgress.bootstrapStepCount;
      final totalActions = cacheOnly
          ? bootstrapSteps
          : bootstrapSteps + (queueTotal > 0 ? queueTotal : 1);

      void emitStep({
        required int stepIndex,
        required int completedActions,
        required String currentActionLabel,
        bool isComplete = false,
        int failedActionCount = 0,
        int conflictCount = 0,
      }) {
        _emit(
          SyncProgress(
            stepIndex: stepIndex,
            stepCount: stepCount,
            stepLabel: SyncProgress.stepLabels[stepIndex.clamp(0, stepCount - 1)],
            progress: totalActions > 0
                ? completedActions / totalActions
                : (stepIndex + 1) / stepCount,
            logs: List.from(logs),
            currentActionLabel: currentActionLabel,
            totalActions: totalActions,
            completedActions: completedActions,
            isComplete: isComplete,
            failedActionCount: failedActionCount,
            conflictCount: conflictCount,
          ),
        );
      }

      emitStep(
        stepIndex: 0,
        completedActions: 0,
        currentActionLabel: queueOnly
            ? 'Envoi des actions en attente'
            : cacheOnly
                ? 'Rechargement du cache'
                : SyncProgress.stepLabels[0],
      );
      _log(logs, 'Vérification des données utilisateur en base locale…');

      await _auth.ensureReadyForBootstrap();
      final email = await _auth.resolveSessionEmail() ?? '';
      if (email.isEmpty) {
        throw AuthException('Profil utilisateur indisponible.');
      }

      final localUser = await _db.findUtilisateurByEmail(email);
      if (localUser == null) {
        throw AuthException(
          'Aucune donnée locale. Connectez-vous au moins une fois en ligne.',
        );
      }
      _log(logs, 'Utilisateur « ${localUser.username} » trouvé.');
      _log(
        logs,
        online ? 'Serveur joignable — synchronisation API.' : 'Mode hors ligne.',
      );

      if (queueOnly) {
        if (!online) {
          throw AuthException(
            'Serveur injoignable. Connectez-vous au réseau pour synchroniser.',
          );
        }
      } else if (cacheOnly) {
        if (!online) {
          throw AuthException(
            'Serveur injoignable. Connectez-vous au réseau pour recharger le cache.',
          );
        }
        emitStep(
          stepIndex: 1,
          completedActions: 0,
          currentActionLabel: 'Organisations',
        );
        final orgs = await _syncOrganizations(online: true, logs: logs);

        emitStep(
          stepIndex: 1,
          completedActions: 1,
          currentActionLabel: SyncProgress.stepLabels[1],
        );
        await _syncThesaurus(
          orgs,
          online: true,
          logs: logs,
          refreshVocabularies: false,
        );
        await _syncVocabularies(
          orgs,
          online: true,
          logs: logs,
          forceRefresh: true,
        );
        await _syncPlaces(orgs, online: true, logs: logs);
        await _syncDirectoryUsers(orgs, online: true, logs: logs);

        emitStep(
          stepIndex: 2,
          completedActions: 2,
          currentActionLabel: SyncProgress.stepLabels[2],
        );
        await _syncForms(orgs, online: true, logs: logs);
        await _syncRecordingUnitTypeForms(orgs, online: true, logs: logs);
        await _syncMobilierTypeForms(orgs, online: true, logs: logs);

        emitStep(
          stepIndex: 3,
          completedActions: 3,
          currentActionLabel: SyncProgress.stepLabels[3],
        );
        await _syncProjects(orgs, online: true, logs: logs);

        _log(logs, 'Cache rechargé depuis le serveur.');
        emitStep(
          stepIndex: 4,
          completedActions: bootstrapSteps,
          currentActionLabel: 'Cache rechargé',
          isComplete: true,
        );
        return;
      } else {
        final orgs = await _syncOrganizations(online: online, logs: logs);

        emitStep(
          stepIndex: 1,
          completedActions: 1,
          currentActionLabel: SyncProgress.stepLabels[1],
        );
        await _syncThesaurus(orgs, online: online, logs: logs);
        await _syncVocabularies(orgs, online: online, logs: logs);
        await _syncPlaces(orgs, online: online, logs: logs);
        await _syncDirectoryUsers(orgs, online: online, logs: logs);

        emitStep(
          stepIndex: 2,
          completedActions: 2,
          currentActionLabel: SyncProgress.stepLabels[2],
        );
        await _syncForms(orgs, online: online, logs: logs);
        await _syncRecordingUnitTypeForms(orgs, online: online, logs: logs);
        await _syncMobilierTypeForms(orgs, online: online, logs: logs);

        emitStep(
          stepIndex: 3,
          completedActions: 3,
          currentActionLabel: SyncProgress.stepLabels[3],
        );
        await _syncProjects(orgs, online: online, logs: logs);

        emitStep(
          stepIndex: 4,
          completedActions: SyncProgress.bootstrapStepCount,
          currentActionLabel: SyncProgress.stepLabels[4],
        );
      }

      var failedActionCount = 0;
      var conflictCount = 0;
      if (!cacheOnly && online && queueTotal > 0) {
        _log(logs, 'Envoi des actions en attente et en échec…');
        final outboxResult = await OutboxSyncEngine(
          auth: _auth,
          db: _db,
        ).syncAll(
          onActionStarted: (action, index, total) {
            final label = SyncQueueItem.fromSyncAction(action).title;
            emitStep(
              stepIndex: 4,
              completedActions: bootstrapSteps + index,
              currentActionLabel: label,
            );
          },
        );
        failedActionCount += outboxResult.failed;
        conflictCount += outboxResult.conflicts;
        if (outboxResult.hasWork) {
          _log(
            logs,
            'File d’attente : ${outboxResult.synced} ok, '
            '${outboxResult.failed} échec(s), '
            '${outboxResult.conflicts} conflit(s).',
          );
        }

        _log(logs, 'Envoi des documents en attente…');
        final uploadResult = await DocumentUploadSync(
          auth: _auth,
          db: _db,
        ).syncPendingUploads(
          onUploadStarted: (entry, index, total) {
            final label = SyncQueueItem.fromDocument(entry).title;
            emitStep(
              stepIndex: 4,
              completedActions: bootstrapSteps + pendingActions.length + index,
              currentActionLabel: label,
            );
          },
        );
        failedActionCount += uploadResult.failed;
        if (uploadResult.hasWork) {
          _log(
            logs,
            'Documents : ${uploadResult.synced} envoyé(s), '
            '${uploadResult.failed} échec(s).',
          );
        }
      } else if (online) {
        _log(logs, 'Aucune action en attente dans la file.');
      }

      final outcome = failedActionCount > 0
          ? 'avec des erreurs'
          : conflictCount > 0
              ? 'avec des conflits'
              : '';
      _log(
        logs,
        outcome.isEmpty
            ? 'Synchronisation terminée.'
            : 'Synchronisation terminée $outcome.',
      );
      emitStep(
        stepIndex: 4,
        completedActions: totalActions,
        currentActionLabel: 'Synchronisation terminée',
        isComplete: true,
        failedActionCount: failedActionCount,
        conflictCount: conflictCount,
      );
    } on AuthException catch (e) {
      _log(logs, 'Erreur : ${e.message}');
      _emit(
        SyncProgress(
          stepIndex: 0,
          stepCount: stepCount,
          stepLabel: SyncProgress.stepLabels[0],
          progress: 0,
          logs: List.from(logs),
          currentActionLabel: SyncProgress.stepLabels[0],
          hasError: true,
          errorMessage: e.message,
        ),
      );
      rethrow;
    } catch (e) {
      _log(logs, 'Erreur inattendue : $e');
      _emit(
        SyncProgress(
          stepIndex: 0,
          stepCount: stepCount,
          stepLabel: SyncProgress.stepLabels[0],
          progress: 0,
          logs: List.from(logs),
          currentActionLabel: SyncProgress.stepLabels[0],
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> _syncThesaurus(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
    bool refreshVocabularies = true,
  }) async {
    final service = ThesaurusSettingsService(auth: _auth, database: _db);
    final store = ThesaurusSettingsStore(_db);

    for (final org in orgs) {
      if (!online) {
        final url = await store.loadUrl(
          organisationId: org.id,
          scope: ThesaurusSettingsScope.user,
        );
        if (url != null && url.isNotEmpty) {
          _log(logs, 'Thésaurus org ${org.id} — cache local.');
        } else {
          _log(
            logs,
            'Thésaurus org ${org.id} — absent (hors ligne, pas de téléchargement).',
          );
        }
        continue;
      }

      _log(logs, 'Thésaurus utilisateur (org ${org.id})…');
      try {
        final synced = await service.bootstrapSyncForOrganisation(
          organisationId: org.id,
          refreshVocabularies: refreshVocabularies,
        );
        if (synced) {
          if (refreshVocabularies) {
            _log(logs, 'Thésaurus et concepts org ${org.id} enregistrés.');
          } else {
            _log(
              logs,
              'Thésaurus org ${org.id} — URL serveur mise en cache '
              '(vocabulaires rechargés à l’étape suivante).',
            );
          }
        } else {
          _log(
            logs,
            refreshVocabularies
                ? 'Thésaurus org ${org.id} — non configuré sur le serveur.'
                : 'Thésaurus org ${org.id} — non configuré sur le serveur '
                    '(vocabulaires re-téléchargés à l’étape suivante).',
          );
        }
      } on AuthException catch (e) {
        _log(
          logs,
          'Thésaurus org ${org.id} — vocabulaires: ${e.message}',
        );
      }
    }
  }

  Future<void> _syncVocabularies(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
    bool forceRefresh = false,
  }) async {
    for (final org in orgs) {
      final cached = await _cachedForm(
        organisationId: org.id,
        type: FormCacheType.vocabulaire,
      );
      if (!forceRefresh && cached != null) {
        final body = _db.decodeFormMap(cached) ?? const {};
        final diagnostic = VocabularyDiagnostic.fromBody(body);
        _log(
          logs,
          'Vocabulaires org ${org.id} — cache local (${diagnostic.summary}).',
        );
        _logVocabularyDiagnostic(logs, orgId: org.id, diagnostic: diagnostic);
        continue;
      }
      if (!online) {
        if (cached != null) {
          _log(
            logs,
            'Vocabulaires org ${org.id} — hors ligne, cache local conservé.',
          );
        } else {
          _log(
            logs,
            'Vocabulaires org ${org.id} — absents (hors ligne, pas de téléchargement).',
          );
        }
        continue;
      }

      if (forceRefresh) {
        _log(
          logs,
          'Re-téléchargement forcé des vocabulaires (org ${org.id})…',
        );
        await _db.clearFormCache(
          organisationId: org.id,
          type: FormCacheType.vocabulaire,
        );
      } else {
        _log(logs, 'Téléchargement vocabulaires (org ${org.id})…');
      }

      try {
        await _downloadAndCacheVocabularies(
          org: org,
          logs: logs,
          source: forceRefresh ? 'Rechargement cache' : 'Bootstrap',
        );
      } on AuthException catch (e) {
        _log(logs, 'Vocabulaires org ${org.id} — ${e.message}');
        rethrow;
      }
    }
  }

  Future<void> _downloadAndCacheVocabularies({
    required Organisation org,
    required List<String> logs,
    required String source,
  }) async {
    final body = await _auth.fetchVocabulariesRaw(organizationId: org.id);
    await _db.replaceForm(
      organisationId: org.id,
      type: FormCacheType.vocabulaire,
      contenuJson: jsonEncode(body),
      ttlDays: _vocabularyTtlDays,
    );
    final diagnostic = VocabularyDiagnostic.fromBody(body);
    _log(logs, 'Vocabulaires org ${org.id} — ${diagnostic.summary}.');
    _logVocabularyDiagnostic(logs, orgId: org.id, diagnostic: diagnostic);
    if (kDebugMode) {
      debugPrint(
        '[Siamois Vocab] $source org ${org.id} — ${diagnostic.summary}',
      );
      for (final line in diagnostic.detailLines) {
        debugPrint('[Siamois Vocab]   $line');
      }
    }
  }

  void _logVocabularyDiagnostic(
    List<String> logs, {
    required int orgId,
    required VocabularyDiagnostic diagnostic,
  }) {
    for (final line in diagnostic.detailLines) {
      _log(logs, 'Vocabulaires org $orgId — $line');
    }
  }

  Future<void> _syncForms(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    for (final org in orgs) {
      await _syncFormType(
        org: org,
        online: online,
        logs: logs,
        type: FormCacheType.projet,
        label: 'projet',
        fetch: () => _auth.fetchProjectFormRaw(organizationId: org.id),
      );
      await _syncFormType(
        org: org,
        online: online,
        logs: logs,
        type: FormCacheType.document,
        label: 'document',
        fetch: () => _auth.fetchDocumentFormRaw(organizationId: org.id),
      );
    }
  }

  Future<void> _syncMobilierTypeForms(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    for (final org in orgs) {
      final types = await _specimenTypesForOrg(org.id, online: online);
      if (types.isEmpty) {
        _log(logs, 'Types mobilier (SIAS.CATEGORY) — aucun pour org ${org.id}.');
        continue;
      }

      _log(logs, '${types.length} type(s) mobilier — org ${org.id}.');
      for (final type in types) {
        final typeId = type.id;
        final cacheType = FormCacheType.typeMobilier(typeId);
        final cached = await _cachedForm(
          organisationId: org.id,
          type: cacheType,
        );
        if (cached != null) continue;

        if (!online) {
          _log(
            logs,
            'Formulaire mobilier type $typeId absent (org ${org.id}) — hors ligne.',
          );
          continue;
        }

        _log(logs, 'Téléchargement formulaire mobilier type $typeId…');
        try {
          final body = await _auth.fetchMobilierFormRaw(
            organizationId: org.id,
            typeConceptId: typeId,
          );
          await _db.replaceForm(
            organisationId: org.id,
            type: cacheType,
            contenuJson: jsonEncode(body),
            ttlDays: _projectFormTtlDays,
          );
          _log(logs, 'Formulaire mobilier type $typeId enregistré.');
        } on AuthException catch (e) {
          _log(logs, 'Formulaire mobilier type $typeId — ${e.message} (ignoré).');
        }
      }
    }
  }

  Future<List<ConceptOption>> _specimenTypesForOrg(
    int orgId, {
    required bool online,
  }) async {
    final vocabRow = await _cachedForm(
      organisationId: orgId,
      type: FormCacheType.vocabulaire,
    );
    if (vocabRow != null) {
      final map = _db.decodeFormMap(vocabRow);
      final data = map?['data'];
      if (data is Map) {
        final vocabs = data['vocabulariesByFieldCode'];
        if (vocabs is Map) {
          final types = ConceptOption.specimenTypesFromVocabularies(
            Map<String, dynamic>.from(vocabs),
          );
          if (types.isNotEmpty) return types;
        }
      }
    }

    if (!online) return const [];

    final body = await _auth.fetchVocabulariesRaw(organizationId: orgId);
    final data = body['data'];
    if (data is! Map) return const [];
    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const [];
    return ConceptOption.specimenTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  Future<void> _syncFormType({
    required Organisation org,
    required bool online,
    required List<String> logs,
    required String type,
    required String label,
    required Future<Map<String, dynamic>> Function() fetch,
  }) async {
    final cached = await _cachedForm(
      organisationId: org.id,
      type: type,
    );
    if (cached != null) {
      _log(logs, 'Formulaire $label org ${org.id} — cache local.');
      return;
    }
    if (!online) {
      _log(
        logs,
        'Formulaire $label org ${org.id} — absent (hors ligne).',
      );
      return;
    }
    _log(logs, 'Téléchargement formulaire $label (org ${org.id})…');
    final body = await fetch();
    await _db.replaceForm(
      organisationId: org.id,
      type: type,
      contenuJson: jsonEncode(body),
      ttlDays: _projectFormTtlDays,
    );
    _log(logs, 'Formulaire $label org ${org.id} enregistré.');
  }

  Future<void> _syncRecordingUnitTypeForms(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    for (final org in orgs) {
      final types = await _recordingUnitTypesForOrg(org.id, online: online);
      if (types.isEmpty) {
        _log(logs, 'Types UE (SIARU.TYPE) — aucun pour org ${org.id}.');
        continue;
      }

      _log(logs, '${types.length} type(s) UE — org ${org.id}.');
      for (final type in types) {
        final typeId = type.id;
        final cacheType = FormCacheType.typeUe(typeId);
        final cached = await _cachedForm(
          organisationId: org.id,
          type: cacheType,
        );
        if (cached != null) continue;

        if (!online) {
          _log(
            logs,
            'Formulaire UE type $typeId absent (org ${org.id}) — hors ligne.',
          );
          continue;
        }

        _log(logs, 'Téléchargement formulaire UE type $typeId…');
        final body = await _auth.fetchRecordingUnitCreationFormRaw(
          organizationId: org.id,
          recordingUnitTypeConceptId: typeId,
        );
        await _db.replaceForm(
          organisationId: org.id,
          type: cacheType,
          contenuJson: jsonEncode(body),
          ttlDays: _projectFormTtlDays,
        );
        _log(logs, 'Formulaire UE type $typeId enregistré.');
      }
    }
  }

  Future<List<ConceptOption>> _recordingUnitTypesForOrg(
    int orgId, {
    required bool online,
  }) async {
    final vocabRow = await _cachedForm(
      organisationId: orgId,
      type: FormCacheType.vocabulaire,
    );
    if (vocabRow != null) {
      final map = _db.decodeFormMap(vocabRow);
      final data = map?['data'];
      if (data is Map) {
        final vocabs = data['vocabulariesByFieldCode'];
        if (vocabs is Map) {
          final types = ConceptOption.recordingUnitTypesFromVocabularies(
            Map<String, dynamic>.from(vocabs),
          );
          if (types.isNotEmpty) return types;
        }
      }
    }

    if (!online) return const [];

    final body = await _auth.fetchVocabulariesRaw(organizationId: orgId);
    final data = body['data'];
    if (data is! Map) return const [];
    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const [];
    return ConceptOption.recordingUnitTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  Future<void> _syncPlaces(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    for (final org in orgs) {
      if (!online) {
        final store = SpatialUnitStore(
          auth: _auth,
          db: _db,
        );
        final count = await store.cachedCount(org.id);
        _log(logs, 'Lieux org ${org.id} — $count en cache local.');
        continue;
      }

      _log(logs, 'Téléchargement des lieux (org ${org.id})…');
      try {
        final store = SpatialUnitStore(
          auth: _auth,
          db: _db,
        );
        final count = await store.syncFromApi(organizationId: org.id);
        _log(logs, '$count lieu(x) enregistrés (org ${org.id}).');
      } on AuthException catch (e) {
        _log(logs, 'Lieux org ${org.id} — ${e.message} (ignoré).');
      }
    }
  }

  Future<void> _syncDirectoryUsers(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    for (final org in orgs) {
      if (!online) {
        final cached = await _db.directoryPersonsForOrganisation(org.id);
        _log(
          logs,
          'Annuaire org ${org.id} — ${cached.length} personne(s) en cache.',
        );
        continue;
      }

      _log(logs, 'Téléchargement annuaire utilisateurs (org ${org.id})…');
      try {
        final people = await _auth.fetchAllOrganizationUsers(
          organizationId: org.id,
        );
        final withConnected = PersonDirectoryStore.mergeForOrganization(
          remote: people,
          profile: _auth.userProfile,
          organizationId: org.id,
        );
        await _db.replaceDirectoryPersonsForOrganisation(
          organisationId: org.id,
          persons: withConnected
              .map(DirectoryPersonInput.fromPersonOption)
              .toList(),
        );
        _log(
          logs,
          '${withConnected.length} personne(s) enregistrées (org ${org.id}).',
        );
      } on AuthException catch (e) {
        _log(logs, 'Annuaire org ${org.id} — ${e.message} (ignoré).');
      } catch (e) {
        _log(logs, 'Annuaire org ${org.id} — erreur : $e (ignoré).');
      }
    }
  }

  Future<List<Organisation>> _syncOrganizations({
    required bool online,
    required List<String> logs,
  }) async {
    if (online) {
      List<StoredOrganization>? apiOrgs;
      try {
        _log(logs, 'Organisations — chargement API…');
        apiOrgs = await _auth.fetchAccessibleOrganizations();
        for (final org in apiOrgs) {
          await _db.upsertOrganisation(id: org.id, nom: org.name);
        }
        if (apiOrgs.isNotEmpty) {
          _auth.replaceOrganizationsInProfile(apiOrgs);
          try {
            await _db.pruneOrganisationsExcept(
              apiOrgs.map((o) => o.id).toSet(),
            );
          } catch (e) {
            _log(
              logs,
              'Nettoyage organisations obsolètes — $e (cache org ${apiOrgs.map((o) => o.id).join(", ")} conservé).',
            );
          }
        }
        _log(logs, '${apiOrgs.length} organisation(s) synchronisée(s).');
      } catch (e) {
        _log(logs, 'Organisations API — $e (cache local conservé).');
      }

      if (apiOrgs != null && apiOrgs.isNotEmpty) {
        return _organizationsPrimaryFirst(
          apiOrgs.map((o) => Organisation(id: o.id, nom: o.name)).toList(),
        );
      }

      if (apiOrgs != null && apiOrgs.isEmpty) {
        final profileOrgs = _auth.userProfile?.organizations ?? const [];
        if (profileOrgs.isNotEmpty) {
          _log(
            logs,
            '${profileOrgs.length} organisation(s) issue(s) du profil utilisateur.',
          );
          for (final org in profileOrgs) {
            await _db.upsertOrganisation(id: org.id, nom: org.name);
          }
          return _organizationsPrimaryFirst(
            profileOrgs
                .map((o) => Organisation(id: o.id, nom: o.name))
                .toList(),
          );
        }

        throw AuthException(AuthMessages.userWithoutOrganization);
      }
    } else {
      final count = (await _db.allOrganisations()).length;
      _log(logs, '$count organisation(s) chargée(s) depuis la base locale.');
    }
    return _organizationsPrimaryFirst(await _db.allOrganisations());
  }

  /// Place l’organisation par défaut (profil) en tête pour la sync formulaires / vocabulaires.
  List<Organisation> _organizationsPrimaryFirst(List<Organisation> orgs) {
    final primaryId = _auth.primaryOrganizationId;
    if (primaryId == null || orgs.length < 2) return orgs;
    final primary = orgs.where((o) => o.id == primaryId).toList();
    if (primary.isEmpty) return orgs;
    final rest = orgs.where((o) => o.id != primaryId).toList();
    return [...primary, ...rest];
  }

  Future<void> _syncProjects(
    List<Organisation> orgs, {
    required bool online,
    required List<String> logs,
  }) async {
    if (online) {
      for (final org in orgs) {
        _log(logs, 'Projets org ${org.id} — chargement API…');
        try {
          final projects = await _auth.fetchAccessibleProjects(
            organizationId: org.id,
          );
          await _db.replaceProjectsForOrganisation(
            organisationId: org.id,
            projects: projects,
          );
          _log(
            logs,
            '${projects.length} projet(s) enregistrés (org ${org.id}).',
          );
        } on AuthException catch (e) {
          _log(logs, 'Projets org ${org.id} — ${e.message} (ignoré).');
        }
      }
    } else {
      final count = (await _db.allProjects()).length;
      if (count == 0) {
        _log(
          logs,
          'Aucun projet en cache — travail hors ligne limité jusqu’à une sync.',
        );
      } else {
        _log(logs, '$count projet(s) chargés depuis la base locale.');
      }
    }
  }

  /// Rafraîchissement manuel (écran projets) si le serveur est joignable.
  Future<int> refreshProjectsOnly({bool replaceCache = false}) async {
    if (!await _auth.canUseProjectsApi()) {
      throw AuthException(
        'Serveur injoignable. Vérifiez la connexion ou réessayez plus tard.',
      );
    }

    final orgs = await _syncOrganizations(online: true, logs: <String>[]);
    var total = 0;
    for (final org in orgs) {
      final projects = await _auth.fetchAccessibleProjects(
        organizationId: org.id,
      );
      total += projects.length;
      if (replaceCache) {
        await _db.replaceProjectsForOrganisation(
          organisationId: org.id,
          projects: projects,
        );
      } else {
        await _db.mergeProjectsForOrganisation(
          organisationId: org.id,
          projects: projects,
        );
      }
    }
    return total;
  }

  /// Liste projets pour l’UI. En ligne, peut recharger depuis l’API avant lecture cache.
  /// Hors ligne (ou API indisponible) : lit uniquement le cache local, sans erreur.
  Future<List<ProjectSummary>> loadProjectsForDisplay({
    bool fetchFromServer = false,
    bool replaceCache = false,
  }) async {
    if (fetchFromServer && await _auth.canUseProjectsApi()) {
      try {
        await refreshProjectsOnly(replaceCache: replaceCache);
      } on AuthException {
        // Cache local ci-dessous.
      } catch (_) {
        // Cache local ci-dessous.
      }
    }

    final orgId = _auth.primaryOrganizationId;
    final rows = orgId != null
        ? await _db.projectsForOrganisation(orgId)
        : await _db.allProjects();
    return rows
        .map(
          (r) => ProjectSummary(
            id: r.id,
            name: r.nom,
            identifier: r.identifiant,
            fullIdentifier: r.fullIdentifier,
            recordingUnitCount: r.recordingUnitCount,
          ),
        )
        .toList();
  }

  void dispose() {
    _controller.close();
  }
}
