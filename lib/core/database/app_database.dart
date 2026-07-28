import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/projects/project_detail_models.dart';
import '../../features/projects/project_models.dart';
import '../../features/projects/form/person_option.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
import '../sync/sync_action_models.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Organisations,
  Utilisateurs,
  Forms,
  Projets,
  ProjetsDetail,
  Documents,
  DocumentsTmp,
  DocumentsUniteEnregistrement,
  UnitesEnregistrement,
  UnitesEnregistrementFavorites,
  UnitesEnregistrementDetail,
  SyncActions,
  EntitySyncSnapshots,
  Mobiliers,
  MobiliersDetail,
  ThesaurusSettings,
  Lieux,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.hadUpgrade && kDebugMode) {
            debugPrint(
              '[Siamois] Migration SQLite ${details.versionBefore} → '
              '${details.versionNow}',
            );
          }
        },
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.deleteTable('projets');
            await m.createTable(projets);
          }
          if (from < 3) {
            await m.createTable(documents);
          }
          if (from < 4) {
            await m.createTable(documentsUniteEnregistrement);
          }
          if (from < 5) {
            await m.createTable(unitesEnregistrement);
            await m.createTable(unitesEnregistrementDetail);
            await m.createTable(mobiliers);
          }
          if (from < 6) {
            await m.addColumn(utilisateurs, utilisateurs.apiPersonId);
          }
          if (from < 7) {
            await m.createTable(documentsTmp);
          }
          if (from < 8) {
            await m.createTable(syncActions);
            await m.createTable(entitySyncSnapshots);
          }
          if (from < 9) {
            await m.createTable(projetsDetail);
          }
          if (from < 10) {
            await m.createTable(mobiliersDetail);
          }
          if (from < 11) {
            await m.addColumn(
              unitesEnregistrement,
              unitesEnregistrement.parentIdsJson,
            );
          }
          if (from < 12) {
            await m.createTable(thesaurusSettings);
          }
          if (from < 13) {
            await customStatement('''
              CREATE TABLE thesaurus_settings_v13 (
                organisation_id INTEGER NOT NULL,
                scope TEXT NOT NULL DEFAULT 'user',
                thesaurus_url TEXT NOT NULL,
                updated_at INTEGER NOT NULL,
                server_synced_at INTEGER,
                PRIMARY KEY (organisation_id, scope),
                FOREIGN KEY (organisation_id) REFERENCES organisations(id)
              )
            ''');
            if (from >= 12) {
              await customStatement('''
                INSERT OR IGNORE INTO thesaurus_settings_v13
                  (organisation_id, scope, thesaurus_url, updated_at, server_synced_at)
                SELECT organisation_id, 'user', thesaurus_url, updated_at, server_synced_at
                FROM thesaurus_settings
              ''');
            }
            await m.deleteTable('thesaurus_settings');
            await customStatement(
              'ALTER TABLE thesaurus_settings_v13 RENAME TO thesaurus_settings',
            );
          }
          if (from < 14) {
            await m.createTable(lieux);
          }
          if (from < 15) {
            await m.addColumn(lieux, lieux.pendingDelete);
            await m.addColumn(lieux, lieux.typeConceptId);
            await m.addColumn(lieux, lieux.addressJson);
          }
          if (from < 16) {
            await m.addColumn(
              thesaurusSettings,
              thesaurusSettings.thesaurusLabel,
            );
            await m.addColumn(
              thesaurusSettings,
              thesaurusSettings.userConfigured,
            );
          }
          if (from < 17) {
            await m.createTable(unitesEnregistrementFavorites);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'siamois_offline');
  }

  /// `creation_date + ttl` jours ≥ maintenant.
  static bool isCacheValid(DateTime creationDate, int ttlDays) {
    if (ttlDays <= 0) return false;
    return DateTime.now().isBefore(creationDate.add(Duration(days: ttlDays)));
  }

  /// Supprime les données téléchargées et la file de sync (conserve la session).
  Future<void> clearOfflineCache() async {
    await transaction(() async {
      await delete(forms).go();
      await delete(projets).go();
      await delete(projetsDetail).go();
      await delete(documents).go();
      await delete(documentsUniteEnregistrement).go();
      await delete(documentsTmp).go();
      await delete(unitesEnregistrement).go();
      await delete(unitesEnregistrementDetail).go();
      await delete(syncActions).go();
      await delete(entitySyncSnapshots).go();
      await delete(mobiliers).go();
      await delete(mobiliersDetail).go();
      await delete(thesaurusSettings).go();
      await delete(lieux).go();
    });
  }

  Future<void> upsertOrganisation({required int id, required String nom}) {
    return into(organisations).insertOnConflictUpdate(
      OrganisationsCompanion(id: Value(id), nom: Value(nom)),
    );
  }

  Future<void> upsertUtilisateur({
    required String nom,
    required String prenom,
    required String email,
    required String username,
    required String password,
    required int idOrganisation,
  }) async {
    final existing = await (select(utilisateurs)
          ..where((u) => u.email.equals(email)))
        .getSingleOrNull();

    final companion = UtilisateursCompanion(
      apiPersonId: const Value(null),
      nom: Value(nom),
      prenom: Value(prenom),
      email: Value(email),
      username: Value(username),
      password: Value(password),
      idOrganisation: Value(idOrganisation),
    );

    if (existing == null) {
      await into(utilisateurs).insert(companion);
    } else {
      await (update(utilisateurs)..where((u) => u.id.equals(existing.id)))
          .write(companion);
    }
  }

  /// Compte de connexion local uniquement (pas l’annuaire).
  Future<Utilisateur?> findUtilisateurByEmail(String email) {
    return (select(utilisateurs)
          ..where(
            (u) => u.email.equals(email.trim()) & u.apiPersonId.isNull(),
          ))
        .getSingleOrNull();
  }

  /// Remplace l’annuaire des personnes d’une organisation (sync démarrage).
  Future<void> replaceDirectoryPersonsForOrganisation({
    required int organisationId,
    required List<DirectoryPersonInput> persons,
  }) async {
    await transaction(() async {
      await (delete(utilisateurs)
            ..where(
              (u) =>
                  u.idOrganisation.equals(organisationId) &
                  u.apiPersonId.isNotNull(),
            ))
          .go();

      if (persons.isEmpty) return;

      // Dédupliquer par apiPersonId (merge profil + API peut doubler une entrée).
      final byApiId = <int, DirectoryPersonInput>{};
      for (final person in persons) {
        byApiId[person.apiPersonId] = person;
      }

      await batch((b) {
        b.insertAll(
          utilisateurs,
          byApiId.values.map((p) => p.toCompanion(organisationId)).toList(),
        );
      });
    });
  }

  Future<List<Utilisateur>> directoryPersonsForOrganisation(
    int organisationId,
  ) {
    return (select(utilisateurs)
          ..where(
            (u) =>
                u.idOrganisation.equals(organisationId) &
                u.apiPersonId.isNotNull(),
          )
          ..orderBy([
            (u) => OrderingTerm(expression: u.nom),
            (u) => OrderingTerm(expression: u.prenom),
          ]))
        .get();
  }

  Future<Utilisateur?> directoryPersonByApiId({
    required int organisationId,
    required int apiPersonId,
  }) {
    return (select(utilisateurs)
          ..where(
            (u) =>
                u.idOrganisation.equals(organisationId) &
                u.apiPersonId.equals(apiPersonId),
          ))
        .getSingleOrNull();
  }

  Future<List<Organisation>> allOrganisations() => select(organisations).get();

  /// Supprime les organisations (et leurs caches) absentes de l’API.
  Future<void> pruneOrganisationsExcept(Set<int> keepIds) async {
    if (keepIds.isEmpty) return;

    final primaryOrgId = keepIds.reduce((a, b) => a < b ? a : b);

    await transaction(() async {
      final staleIds = await (selectOnly(organisations)
            ..addColumns([organisations.id])
            ..where(organisations.id.isNotIn(keepIds.toList())))
          .map((row) => row.read(organisations.id)!)
          .get();

      if (staleIds.isEmpty) return;

      // Compte de connexion local : réaffecter avant suppression de l’org.
      for (final organisationId in staleIds) {
        await (update(utilisateurs)
              ..where(
                (u) =>
                    u.idOrganisation.equals(organisationId) &
                    u.apiPersonId.isNull(),
              ))
            .write(
              UtilisateursCompanion(idOrganisation: Value(primaryOrgId)),
            );
      }

      for (final organisationId in staleIds) {
        await (delete(forms)
              ..where((f) => f.idOrganisation.equals(organisationId)))
            .go();
        await (delete(projets)
              ..where((p) => p.idOrganisation.equals(organisationId)))
            .go();
        await (delete(utilisateurs)
              ..where(
                (u) =>
                    u.idOrganisation.equals(organisationId) &
                    u.apiPersonId.isNotNull(),
              ))
            .go();
      }

      await (delete(organisations)
            ..where((o) => o.id.isNotIn(keepIds.toList())))
          .go();
    });
  }

  Future<Form?> findValidForm({
    required int organisationId,
    required String type,
  }) async {
    final row = await (select(forms)
          ..where(
            (f) =>
                f.idOrganisation.equals(organisationId) &
                f.type.equals(type),
          )
          ..orderBy([(f) => OrderingTerm.desc(f.creationDate)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    if (!isCacheValid(row.creationDate, row.ttl)) return null;
    return row;
  }

  /// Dernière version en cache, même si le TTL est expiré (édition hors ligne).
  Future<Form?> findLatestForm({
    required int organisationId,
    required String type,
  }) async {
    return (select(forms)
          ..where(
            (f) =>
                f.idOrganisation.equals(organisationId) &
                f.type.equals(type),
          )
          ..orderBy([(f) => OrderingTerm.desc(f.creationDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Cache valide ou, à défaut, dernière version synchronisée (mode hors ligne).
  Future<Form?> findCachedForm({
    required int organisationId,
    required String type,
  }) async {
    final valid = await findValidForm(
      organisationId: organisationId,
      type: type,
    );
    if (valid != null) return valid;
    return findLatestForm(
      organisationId: organisationId,
      type: type,
    );
  }

  Future<void> clearFormCache({
    required int organisationId,
    required String type,
  }) async {
    await (delete(forms)
          ..where(
            (f) =>
                f.idOrganisation.equals(organisationId) &
                f.type.equals(type),
          ))
        .go();
  }

  Future<void> replaceForm({
    required int organisationId,
    required String type,
    required String contenuJson,
    required int ttlDays,
  }) async {
    await clearFormCache(organisationId: organisationId, type: type);
    await into(forms).insert(
      FormsCompanion.insert(
        type: type,
        contenu: contenuJson,
        ttl: ttlDays,
        creationDate: DateTime.now(),
        idOrganisation: organisationId,
      ),
    );
  }

  Future<ThesaurusSettingRow?> findThesaurusSetting({
    required int organisationId,
    required String scope,
  }) {
    return (select(thesaurusSettings)
          ..where(
            (t) =>
                t.organisationId.equals(organisationId) &
                t.scope.equals(scope),
          ))
        .getSingleOrNull();
  }

  Future<void> upsertThesaurusSetting({
    required int organisationId,
    required String scope,
    required String thesaurusUrl,
    DateTime? serverSyncedAt,
    String? thesaurusLabel,
    bool? userConfigured,
  }) async {
    final now = DateTime.now();
    await into(thesaurusSettings).insertOnConflictUpdate(
      ThesaurusSettingsCompanion(
        organisationId: Value(organisationId),
        scope: Value(scope),
        thesaurusUrl: Value(thesaurusUrl.trim()),
        thesaurusLabel: thesaurusLabel == null
            ? const Value.absent()
            : Value(
                thesaurusLabel.trim().isEmpty ? null : thesaurusLabel.trim(),
              ),
        userConfigured: userConfigured == null
            ? const Value.absent()
            : Value(userConfigured),
        updatedAt: Value(now),
        serverSyncedAt: Value(serverSyncedAt),
      ),
    );
  }

  String? decodeFormJson(Form row) {
    if (row.contenu.isEmpty) return null;
    return row.contenu;
  }

  Map<String, dynamic>? decodeFormMap(Form row) {
    try {
      final decoded = jsonDecode(row.contenu);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static ProjetsCompanion companionFromSummary(
    ProjectSummary project,
    int organisationId,
  ) {
    return ProjetsCompanion.insert(
      id: project.storageId,
      nom: project.name,
      identifiant: Value(project.identifier),
      fullIdentifier: Value(project.fullIdentifier),
      recordingUnitCount: Value(project.recordingUnitCount),
      idOrganisation: organisationId,
    );
  }

  Future<void> mergeProjectsForOrganisation({
    required int organisationId,
    required List<ProjectSummary> projects,
  }) async {
    final companions = <ProjetsCompanion>[];
    final seen = <String>{};
    for (final p in projects) {
      final key = p.storageId;
      if (key.startsWith('local:')) continue;
      if (!seen.add(key)) continue;
      companions.add(companionFromSummary(p, organisationId));
    }

    if (companions.isEmpty) return;

    await batch((b) {
      b.insertAll(
        projets,
        companions,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> replaceProjectsForOrganisation({
    required int organisationId,
    required List<ProjectSummary> projects,
  }) async {
    final companions = <ProjetsCompanion>[];
    final seen = <String>{};
    for (final p in projects) {
      final key = p.storageId;
      if (key.startsWith('local:')) continue;
      if (!seen.add(key)) continue;
      companions.add(companionFromSummary(p, organisationId));
    }

    await transaction(() async {
      await (delete(projets)
            ..where(
              (p) =>
                  p.idOrganisation.equals(organisationId) &
                  p.id.like('local:%').not(),
            ))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            projets,
            companions,
            mode: InsertMode.insertOrReplace,
          );
        });
      }
    });
  }

  Future<List<Projet>> projectsForOrganisation(int organisationId) {
    return (select(projets)
          ..where((p) => p.idOrganisation.equals(organisationId))
          ..orderBy([(p) => OrderingTerm(expression: p.nom)]))
        .get();
  }

  Future<List<Projet>> allProjects() {
    return (select(projets)..orderBy([(p) => OrderingTerm(expression: p.nom)]))
        .get();
  }

  /// Met à jour ou insère un projet après création / modification API.
  Future<void> upsertProjet({
    required ProjectSummary project,
    required int organisationId,
  }) async {
    await into(projets).insertOnConflictUpdate(
      companionFromSummary(project, organisationId),
    );
  }

  /// Supprime un projet du cache local (et éventuellement ses enfants locaux).
  Future<void> deleteProjectFromCache({
    required String projectId,
    required int organisationId,
    required bool cascadeChildren,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) return;

    await transaction(() async {
      if (cascadeChildren) {
        final recordingUnits = await recordingUnitsForProject(key);
        for (final ru in recordingUnits) {
          await deleteRecordingUnitByResourceId(ru.resourceId);
        }

        final tmpRows = await documentTmpForProject(key);
        for (final row in tmpRows) {
          await deleteDocumentTmp(row.localId);
        }
      }

      await (delete(documents)..where((d) => d.projectId.equals(key))).go();
      await (delete(projets)
            ..where(
              (p) => p.id.equals(key) & p.idOrganisation.equals(organisationId),
            ))
          .go();
      await (delete(projetsDetail)..where((d) => d.resourceId.equals(key)))
          .go();
    });
  }

  /// Retire les actions outbox liées à un projet (y compris créations UE en attente).
  Future<void> purgeOutboxForProject(String projectId) async {
    final key = projectId.trim();
    if (key.isEmpty) return;

    final rows = await select(syncActions).get();
    for (final row in rows) {
      if (_syncActionReferencesProject(row, key)) {
        await deleteSyncAction(row.actionId);
      }
    }
  }

  bool _syncActionReferencesProject(SyncActionRow row, String projectId) {
    if (row.localEntityId == projectId || row.serverEntityId == projectId) {
      return true;
    }

    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map) return false;
      final map = Map<String, dynamic>.from(decoded);
      for (final field in ['actionUnitId', 'projectId', 'parentId']) {
        if (map[field]?.toString() == projectId) return true;
      }
    } catch (_) {}

    return false;
  }

  Future<Projet?> findProjetRow(String projectId) async {
    final key = projectId.trim();
    if (key.isEmpty) return null;

    final byId = await (select(projets)..where((p) => p.id.equals(key)))
        .getSingleOrNull();
    if (byId != null) return byId;

    return (select(projets)..where((p) => p.fullIdentifier.equals(key)))
        .getSingleOrNull();
  }

  Future<void> replaceProjectDetail({
    required String resourceId,
    required String detailJson,
  }) async {
    await into(projetsDetail).insertOnConflictUpdate(
      ProjetsDetailCompanion.insert(
        resourceId: resourceId,
        detailJson: detailJson,
        syncedAt: DateTime.now(),
      ),
    );
  }

  Future<ProjetDetailRow?> projectDetailRow(String resourceId) {
    return (select(projetsDetail)
          ..where((p) => p.resourceId.equals(resourceId.trim())))
        .getSingleOrNull();
  }

  static DocumentsCompanion companionFromDocumentItem(
    ProjectDocumentItem item,
    String projectId,
  ) {
    return DocumentsCompanion.insert(
      resourceId: item.id,
      titre: item.title,
      description: Value(item.description),
      fileName: Value(item.fileName),
      mimeType: Value(item.mimeType),
      url: Value(item.url),
      fileCode: Value(item.fileCode),
      projectId: projectId,
    );
  }

  /// Remplace tous les documents d’un projet (sync API).
  Future<void> replaceDocumentsForProject({
    required String projectId,
    required List<ProjectDocumentItem> items,
  }) async {
    final companions = items
        .where((d) => d.id.trim().isNotEmpty)
        .map((d) => companionFromDocumentItem(d, projectId))
        .toList();

    final table = this.documents;
    await transaction(() async {
      await (delete(table)..where((d) => d.projectId.equals(projectId))).go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, companions);
        });
      }
    });
  }

  Future<List<Document>> documentsForProject(String projectId) {
    final table = this.documents;
    return (select(table)
          ..where((d) => d.projectId.equals(projectId))
          ..orderBy([(d) => OrderingTerm(expression: d.titre)]))
        .get();
  }

  Future<int> countDocumentsForProject(String projectId) async {
    final expr = documents.projectId.count();
    final query = selectOnly(documents)
      ..addColumns([expr])
      ..where(documents.projectId.equals(projectId));
    final row = await query.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<void> upsertDocument({
    required ProjectDocumentItem item,
    required String projectId,
  }) async {
    await into(this.documents).insertOnConflictUpdate(
      companionFromDocumentItem(item, projectId),
    );
  }

  Future<void> deleteDocumentByResourceId(String resourceId) async {
    await (delete(this.documents)
          ..where((d) => d.resourceId.equals(resourceId)))
        .go();
  }

  static DocumentsUniteEnregistrementCompanion
      companionFromDocumentItemForRecordingUnit(
    ProjectDocumentItem item,
    String uniteEnregistrementId,
  ) {
    return DocumentsUniteEnregistrementCompanion.insert(
      resourceId: item.id,
      titre: item.title,
      description: Value(item.description),
      fileName: Value(item.fileName),
      mimeType: Value(item.mimeType),
      url: Value(item.url),
      fileCode: Value(item.fileCode),
      uniteEnregistrementId: uniteEnregistrementId,
    );
  }

  /// Remplace tous les documents d’une UE (sync API).
  Future<void> replaceDocumentsForRecordingUnit({
    required String uniteEnregistrementId,
    required List<ProjectDocumentItem> items,
  }) async {
    final companions = items
        .where((d) => d.id.trim().isNotEmpty)
        .map(
          (d) => companionFromDocumentItemForRecordingUnit(
            d,
            uniteEnregistrementId,
          ),
        )
        .toList();

    final table = documentsUniteEnregistrement;
    await transaction(() async {
      await (delete(table)
            ..where(
              (d) => d.uniteEnregistrementId.equals(uniteEnregistrementId),
            ))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, companions);
        });
      }
    });
  }

  Future<List<DocumentUniteEnregistrement>> documentsForRecordingUnit(
    String uniteEnregistrementId,
  ) {
    final table = documentsUniteEnregistrement;
    return (select(table)
          ..where((d) => d.uniteEnregistrementId.equals(uniteEnregistrementId))
          ..orderBy([(d) => OrderingTerm(expression: d.titre)]))
        .get();
  }

  Future<void> upsertRecordingUnitDocument({
    required ProjectDocumentItem item,
    required String uniteEnregistrementId,
  }) async {
    await into(documentsUniteEnregistrement).insertOnConflictUpdate(
      companionFromDocumentItemForRecordingUnit(item, uniteEnregistrementId),
    );
  }

  Future<void> deleteRecordingUnitDocumentByResourceId(String resourceId) async {
    await (delete(documentsUniteEnregistrement)
          ..where((d) => d.resourceId.equals(resourceId)))
        .go();
  }

  // —— Documents temporaires (binaires offline) ——

  Future<void> insertDocumentTmp({
    required String localId,
    required String parentType,
    required String parentId,
    required String kind,
    required String status,
    required String titre,
    required Uint8List fileContent,
    String? resourceId,
    String? description,
    String? fileName,
    String? mimeType,
    String? fileCode,
    String? url,
    int? natureConceptId,
    int? scaleConceptId,
    int? formatConceptId,
    String? uploadError,
  }) async {
    final now = DateTime.now();
    await into(documentsTmp).insert(
      DocumentsTmpCompanion.insert(
        localId: localId,
        resourceId: Value(resourceId),
        parentType: parentType,
        parentId: parentId,
        kind: kind,
        status: status,
        titre: titre,
        description: Value(description),
        fileName: Value(fileName),
        mimeType: Value(mimeType),
        fileCode: Value(fileCode),
        url: Value(url),
        natureConceptId: Value(natureConceptId),
        scaleConceptId: Value(scaleConceptId),
        formatConceptId: Value(formatConceptId),
        fileContent: fileContent,
        fileSize: Value(fileContent.length),
        uploadError: Value(uploadError),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> upsertDocumentTmpPrefetch({
    required String localId,
    required String resourceId,
    required String parentType,
    required String parentId,
    required String titre,
    required Uint8List fileContent,
    String? description,
    String? fileName,
    String? mimeType,
    String? fileCode,
    String? url,
  }) async {
    final now = DateTime.now();
    await into(documentsTmp).insertOnConflictUpdate(
      DocumentsTmpCompanion(
        localId: Value(localId),
        resourceId: Value(resourceId),
        parentType: Value(parentType),
        parentId: Value(parentId),
        kind: const Value('prefetch'),
        status: const Value('synced'),
        titre: Value(titre),
        description: Value(description),
        fileName: Value(fileName),
        mimeType: Value(mimeType),
        fileCode: Value(fileCode),
        url: Value(url),
        fileContent: Value(fileContent),
        fileSize: Value(fileContent.length),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<DocumentTmpRow?> documentTmpByLocalId(String localId) {
    return (select(documentsTmp)
          ..where((d) => d.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<DocumentTmpRow?> documentTmpByResourceId(String resourceId) {
    return (select(documentsTmp)
          ..where((d) => d.resourceId.equals(resourceId)))
        .getSingleOrNull();
  }

  Future<List<DocumentTmpRow>> pendingUploadDocumentsTmp() {
    return (select(documentsTmp)
          ..where(
            (d) =>
                d.kind.equals('pending_upload') &
                d.status.isIn(['pending', 'failed']),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.createdAt)]))
        .get();
  }

  /// Documents à envoyer (affichage file d’attente : inclut l’envoi en cours).
  Future<List<DocumentTmpRow>> queueUploadDocumentsTmp() {
    return (select(documentsTmp)
          ..where(
            (d) =>
                d.kind.equals('pending_upload') &
                d.status.isIn(['pending', 'uploading', 'failed']),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.createdAt)]))
        .get();
  }

  Future<List<DocumentTmpRow>> documentTmpForProject(String projectId) {
    return (select(documentsTmp)
          ..where(
            (d) =>
                d.parentType.equals('project') &
                d.parentId.equals(projectId),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.titre)]))
        .get();
  }

  Future<List<DocumentTmpRow>> documentTmpForRecordingUnit(
    String recordingUnitId,
  ) {
    return (select(documentsTmp)
          ..where(
            (d) =>
                d.parentType.equals('recording_unit') &
                d.parentId.equals(recordingUnitId),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.titre)]))
        .get();
  }

  Future<void> updateDocumentTmpStatus({
    required String localId,
    required String status,
    String? resourceId,
    String? uploadError,
  }) async {
    await (update(documentsTmp)..where((d) => d.localId.equals(localId))).write(
      DocumentsTmpCompanion(
        status: Value(status),
        resourceId: resourceId != null ? Value(resourceId) : const Value.absent(),
        uploadError:
            uploadError != null ? Value(uploadError) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteDocumentTmp(String localId) async {
    await (delete(documentsTmp)..where((d) => d.localId.equals(localId))).go();
  }

  Future<void> deleteDocumentTmpByResourceId(String resourceId) async {
    await (delete(documentsTmp)
          ..where((d) => d.resourceId.equals(resourceId)))
        .go();
  }

  // —— Outbox (sync_actions) ——

  Future<int> nextSyncActionSequence() async {
    final row = await customSelect(
      'SELECT COALESCE(MAX(sequence), 0) + 1 AS n FROM sync_actions',
      readsFrom: {syncActions},
    ).getSingle();
    return row.read<int>('n');
  }

  Future<void> insertSyncAction({
    required String actionId,
    required int sequence,
    required String operation,
    required String entityType,
    required String payloadJson,
    required String status,
    String? localEntityId,
    String? serverEntityId,
    String? parentType,
    String? parentLocalId,
    String? parentServerId,
    String? blobRef,
    int? baseServerRevision,
    String? errorMessage,
  }) async {
    final now = DateTime.now();
    await into(syncActions).insert(
      SyncActionsCompanion.insert(
        actionId: actionId,
        sequence: sequence,
        operation: operation,
        entityType: entityType,
        localEntityId: Value(localEntityId),
        serverEntityId: Value(serverEntityId),
        parentType: Value(parentType),
        parentLocalId: Value(parentLocalId),
        parentServerId: Value(parentServerId),
        payloadJson: payloadJson,
        blobRef: Value(blobRef),
        baseServerRevision: Value(baseServerRevision),
        status: status,
        errorMessage: Value(errorMessage),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Remet en file les actions échouées, en conflit ou bloquées en envoi.
  Future<void> resetSyncActionsForRetry() async {
    final now = DateTime.now();
    await (update(syncActions)..where(
          (a) => a.status.isIn([
            SyncActionStatus.failed,
            SyncActionStatus.conflict,
            SyncActionStatus.uploading,
          ]),
        ))
        .write(
      SyncActionsCompanion(
        status: const Value(SyncActionStatus.pending),
        errorMessage: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Remet en attente les uploads documents échoués ou bloqués.
  Future<void> resetDocumentUploadsForRetry() async {
    final now = DateTime.now();
    await (update(documentsTmp)..where(
          (d) =>
              d.kind.equals('pending_upload') &
              d.status.isIn(['failed', 'uploading']),
        ))
        .write(
      DocumentsTmpCompanion(
        status: const Value('pending'),
        uploadError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<SyncActionRow>> pendingSyncActions() {
    return (select(syncActions)
          ..where(
            (a) => a.status.isIn([
              SyncActionStatus.pending,
              SyncActionStatus.failed,
              SyncActionStatus.conflict,
              SyncActionStatus.uploading,
            ]),
          )
          ..orderBy([(a) => OrderingTerm(expression: a.sequence)]))
        .get();
  }

  Future<int> countPendingSyncActions() async {
    final rows = await (select(syncActions)
          ..where(
            (a) => a.status.isIn([
              SyncActionStatus.pending,
              SyncActionStatus.failed,
              SyncActionStatus.conflict,
              SyncActionStatus.uploading,
            ]),
          ))
        .get();
    return rows.length;
  }

  Future<void> updateSyncActionStatus({
    required String actionId,
    required String status,
    String? errorMessage,
    String? serverEntityId,
  }) async {
    await (update(syncActions)..where((a) => a.actionId.equals(actionId))).write(
      SyncActionsCompanion(
        status: Value(status),
        errorMessage:
            errorMessage != null ? Value(errorMessage) : const Value.absent(),
        serverEntityId:
            serverEntityId != null ? Value(serverEntityId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateSyncActionPayload({
    required String actionId,
    required String payloadJson,
  }) async {
    await (update(syncActions)..where((a) => a.actionId.equals(actionId))).write(
      SyncActionsCompanion(
        payloadJson: Value(payloadJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSyncActionsForLocalEntity(String localEntityId) async {
    final key = localEntityId.trim();
    if (key.isEmpty) return;
    await (delete(syncActions)..where((a) => a.localEntityId.equals(key))).go();
  }

  Future<SyncActionRow?> syncActionById(String actionId) {
    return (select(syncActions)..where((a) => a.actionId.equals(actionId)))
        .getSingleOrNull();
  }

  Future<void> deleteSyncAction(String actionId) async {
    await (delete(syncActions)..where((a) => a.actionId.equals(actionId))).go();
  }

  Future<void> requeueSyncActionAfterRebase({
    required String actionId,
    required int baseServerRevision,
  }) async {
    await (update(syncActions)..where((a) => a.actionId.equals(actionId))).write(
      SyncActionsCompanion(
        status: const Value(SyncActionStatus.pending),
        baseServerRevision: Value(baseServerRevision),
        errorMessage: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertEntitySyncSnapshot({
    required String entityType,
    required String entityId,
    required int baseServerRevision,
    required String snapshotJson,
  }) async {
    final now = DateTime.now();
    await into(entitySyncSnapshots).insertOnConflictUpdate(
      EntitySyncSnapshotsCompanion(
        entityType: Value(entityType),
        entityId: Value(entityId),
        baseServerRevision: Value(baseServerRevision),
        snapshotJson: Value(snapshotJson),
        updatedAt: Value(now),
      ),
    );
  }

  Future<EntitySyncSnapshotRow?> entitySyncSnapshot(
    String entityType,
    String entityId,
  ) {
    return (select(entitySyncSnapshots)
          ..where(
            (s) =>
                s.entityType.equals(entityType) & s.entityId.equals(entityId),
          ))
        .getSingleOrNull();
  }

  static UnitesEnregistrementCompanion companionFromRecordingUnitItem(
    RecordingUnitItem item,
    String projectId, {
    int? typeConceptId,
  }) {
    return UnitesEnregistrementCompanion.insert(
      resourceId: item.id,
      projectId: projectId,
      displayCode: item.displayCode,
      identifier: Value(item.identifier),
      typeLabel: Value(item.typeLabel),
      placeLabel: Value(item.placeLabel),
      openingDate: Value(item.openingDate),
      closingDate: Value(item.closingDate),
      matrixColor: Value(item.matrixColor),
      specimenCount: Value(item.specimenCount),
      stratigraphicCount: Value(item.stratigraphicCount),
      typeConceptId: Value(typeConceptId),
      parentIdsJson: Value(_encodeParentIds(item.parentIds)),
      syncedAt: DateTime.now(),
    );
  }

  static String? _encodeParentIds(List<String> parentIds) {
    if (parentIds.isEmpty) return null;
    return jsonEncode(parentIds);
  }

  static List<String> decodeParentIdsForRecordingUnit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> replaceRecordingUnitsForProject({
    required String projectId,
    required List<RecordingUnitItem> items,
    Map<String, int>? typeConceptIdsByResourceId,
  }) async {
    final companions = items
        .where((u) => u.id.trim().isNotEmpty)
        .map(
          (u) => companionFromRecordingUnitItem(
            u,
            projectId,
            typeConceptId: typeConceptIdsByResourceId?[u.id],
          ),
        )
        .toList();

    final table = unitesEnregistrement;
    final pendingLocal = await (select(table)
          ..where(
            (u) =>
                u.projectId.equals(projectId) &
                u.resourceId.like('local:%'),
          ))
        .get();

    await transaction(() async {
      await (delete(table)
            ..where(
              (u) =>
                  u.projectId.equals(projectId) &
                  u.resourceId.like('local:%').not(),
            ))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, companions);
        });
      }
      if (pendingLocal.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, pendingLocal);
        });
      }
    });
  }

  /// Remplace l’identifiant local (`local:…`) par l’id serveur après création.
  Future<void> remapRecordingUnitResourceId({
    required String fromResourceId,
    required String toResourceId,
  }) async {
    final from = fromResourceId.trim();
    final to = toResourceId.trim();
    if (from.isEmpty || to.isEmpty || from == to) return;

    await transaction(() async {
      final listRow = await (select(unitesEnregistrement)
            ..where((u) => u.resourceId.equals(from)))
          .getSingleOrNull();
      if (listRow != null) {
        await (delete(unitesEnregistrement)
              ..where((u) => u.resourceId.equals(from)))
            .go();
        await into(unitesEnregistrement).insert(
          UnitesEnregistrementCompanion.insert(
            resourceId: to,
            projectId: listRow.projectId,
            displayCode: listRow.displayCode,
            identifier: Value(listRow.identifier),
            typeLabel: Value(listRow.typeLabel),
            placeLabel: Value(listRow.placeLabel),
            openingDate: Value(listRow.openingDate),
            closingDate: Value(listRow.closingDate),
            matrixColor: Value(listRow.matrixColor),
            specimenCount: Value(listRow.specimenCount),
            stratigraphicCount: Value(listRow.stratigraphicCount),
            typeConceptId: Value(listRow.typeConceptId),
            syncedAt: DateTime.now(),
          ),
        );
      }

      final detailRow = await recordingUnitDetailRow(from);
      if (detailRow != null) {
        var detailJson = detailRow.detailJson;
        try {
          final decoded = jsonDecode(detailRow.detailJson);
          if (decoded is Map) {
            final map = Map<String, dynamic>.from(decoded);
            final ruRaw = map['recordingUnit'];
            if (ruRaw is Map) {
              final ru = Map<String, dynamic>.from(ruRaw);
              ru['resourceId'] = to;
              ru.remove('_pendingCreate');
              map['recordingUnit'] = ru;
            }
            detailJson = jsonEncode(map);
          }
        } catch (_) {
          // Conserve le JSON tel quel si parsing impossible.
        }

        await (delete(unitesEnregistrementDetail)
              ..where((d) => d.resourceId.equals(from)))
            .go();
        await replaceRecordingUnitDetail(
          resourceId: to,
          detailJson: detailJson,
          typeConceptId: detailRow.typeConceptId,
        );
      }

      final snapshot = await entitySyncSnapshot(
        SyncEntityType.recordingUnit,
        from,
      );
      if (snapshot != null) {
        await (delete(entitySyncSnapshots)
              ..where(
                (s) =>
                    s.entityType.equals(SyncEntityType.recordingUnit) &
                    s.entityId.equals(from),
              ))
            .go();
        await upsertEntitySyncSnapshot(
          entityType: SyncEntityType.recordingUnit,
          entityId: to,
          baseServerRevision: snapshot.baseServerRevision,
          snapshotJson: snapshot.snapshotJson,
        );
      }

      await (update(syncActions)..where((a) => a.serverEntityId.equals(from)))
          .write(SyncActionsCompanion(serverEntityId: Value(to)));
      await (update(syncActions)..where((a) => a.localEntityId.equals(from)))
          .write(SyncActionsCompanion(localEntityId: Value(to)));

      await (update(mobiliers)
            ..where((m) => m.uniteEnregistrementId.equals(from)))
          .write(MobiliersCompanion(uniteEnregistrementId: Value(to)));

      await (update(documentsUniteEnregistrement)
            ..where((d) => d.uniteEnregistrementId.equals(from)))
          .write(
        DocumentsUniteEnregistrementCompanion(
          uniteEnregistrementId: Value(to),
        ),
      );

      await (update(documentsTmp)
            ..where(
              (d) =>
                  d.parentType.equals('recording_unit') &
                  d.parentId.equals(from),
            ))
          .write(DocumentsTmpCompanion(parentId: Value(to)));

      await _remapRecordingUnitFavoriteResourceId(from: from, to: to);
      await _remapMobilierOutboxRecordingUnitIds(from: from, to: to);
    });
  }

  Future<void> _remapRecordingUnitFavoriteResourceId({
    required String from,
    required String to,
  }) async {
    final rows = await (select(unitesEnregistrementFavorites)
          ..where((f) => f.resourceId.equals(from)))
        .get();
    for (final row in rows) {
      await (delete(unitesEnregistrementFavorites)
            ..where(
              (f) =>
                  f.userKey.equals(row.userKey) & f.resourceId.equals(from),
            ))
          .go();
      await into(unitesEnregistrementFavorites).insertOnConflictUpdate(
        UnitesEnregistrementFavoritesCompanion.insert(
          userKey: row.userKey,
          resourceId: to,
          projectId: row.projectId,
          createdAt: row.createdAt,
        ),
      );
    }
  }

  /// Remplace l’identifiant local (`local:…`) par l’id serveur après création projet.
  Future<void> remapProjectResourceId({
    required String fromResourceId,
    required String toResourceId,
    required int organisationId,
  }) async {
    final from = fromResourceId.trim();
    final to = toResourceId.trim();
    if (from.isEmpty || to.isEmpty || from == to) return;

    await transaction(() async {
      final listRow = await (select(projets)
            ..where(
              (p) => p.id.equals(from) & p.idOrganisation.equals(organisationId),
            ))
          .getSingleOrNull();
      if (listRow != null) {
        await (delete(projets)
              ..where(
                (p) =>
                    p.id.equals(from) & p.idOrganisation.equals(organisationId),
              ))
            .go();
        final existingTarget = await (select(projets)
              ..where(
                (p) =>
                    p.id.equals(to) & p.idOrganisation.equals(organisationId),
              ))
            .getSingleOrNull();
        if (existingTarget == null) {
          await into(projets).insert(
            ProjetsCompanion.insert(
              id: to,
              nom: listRow.nom,
              identifiant: Value(listRow.identifiant),
              fullIdentifier: Value(listRow.fullIdentifier),
              recordingUnitCount: Value(listRow.recordingUnitCount),
              idOrganisation: organisationId,
            ),
          );
        }
      }

      final detailRow = await projectDetailRow(from);
      if (detailRow != null) {
        var detailJson = detailRow.detailJson;
        try {
          final decoded = jsonDecode(detailRow.detailJson);
          if (decoded is Map) {
            final map = Map<String, dynamic>.from(decoded);
            map['id'] = to;
            map.remove('_pendingCreate');
            detailJson = jsonEncode(map);
          }
        } catch (_) {
          // Conserve le JSON tel quel si parsing impossible.
        }

        await (delete(projetsDetail)..where((d) => d.resourceId.equals(from)))
            .go();
        final existingDetail = await projectDetailRow(to);
        if (existingDetail == null) {
          await replaceProjectDetail(
            resourceId: to,
            detailJson: detailJson,
          );
        }
      }

      await (update(unitesEnregistrement)
            ..where((u) => u.projectId.equals(from)))
          .write(UnitesEnregistrementCompanion(projectId: Value(to)));

      await (update(documents)..where((d) => d.projectId.equals(from)))
          .write(DocumentsCompanion(projectId: Value(to)));

      await (update(documentsTmp)
            ..where(
              (d) =>
                  d.parentType.equals('project') & d.parentId.equals(from),
            ))
          .write(DocumentsTmpCompanion(parentId: Value(to)));

      await (update(syncActions)..where((a) => a.serverEntityId.equals(from)))
          .write(SyncActionsCompanion(serverEntityId: Value(to)));
      await (update(syncActions)..where((a) => a.localEntityId.equals(from)))
          .write(SyncActionsCompanion(localEntityId: Value(to)));

      await _remapOutboxProjectIds(from: from, to: to);
    });
  }

  Future<void> _remapOutboxProjectIds({
    required String from,
    required String to,
  }) async {
    final rows = await (select(syncActions)
          ..where(
            (a) =>
                a.status.isIn(['pending', 'failed', 'conflict', 'uploading']),
          ))
        .get();

    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.payloadJson);
        if (decoded is! Map) continue;
        final map = Map<String, dynamic>.from(decoded);
        var changed = false;

        for (final key in ['actionUnitId', 'projectId']) {
          if (map[key]?.toString() == from) {
            map[key] = to;
            changed = true;
          }
        }

        if (!changed) continue;
        await (update(syncActions)..where((a) => a.actionId.equals(row.actionId)))
            .write(
          SyncActionsCompanion(
            payloadJson: Value(jsonEncode(map)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } catch (_) {
        // Ignore les payloads invalides.
      }
    }
  }

  /// Met à jour les créations mobilier en attente après sync de l’UE parente.
  Future<void> _remapMobilierOutboxRecordingUnitIds({
    required String from,
    required String to,
  }) async {
    final rows = await (select(syncActions)
          ..where((a) => a.entityType.equals(SyncEntityType.mobilier)))
        .get();

    for (final row in rows) {
      if (!['pending', 'failed', 'conflict'].contains(row.status)) continue;
      try {
        final decoded = jsonDecode(row.payloadJson);
        if (decoded is! Map) continue;
        final map = Map<String, dynamic>.from(decoded);
        if (map['recordingUnitId']?.toString() != from) continue;
        map['recordingUnitId'] = to;
        await (update(syncActions)..where((a) => a.actionId.equals(row.actionId)))
            .write(
          SyncActionsCompanion(
            payloadJson: Value(jsonEncode(map)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } catch (_) {
        // Ignore les payloads invalides.
      }
    }
  }

  /// Remplace l’identifiant local (`local:…`) par l’id serveur après création.
  Future<void> remapMobilierResourceId({
    required String fromResourceId,
    required String toResourceId,
  }) async {
    final from = fromResourceId.trim();
    final to = toResourceId.trim();
    if (from.isEmpty || to.isEmpty || from == to) return;

    await transaction(() async {
      final listRow = await (select(mobiliers)
            ..where((m) => m.resourceId.equals(from)))
          .getSingleOrNull();
      if (listRow != null) {
        await (delete(mobiliers)..where((m) => m.resourceId.equals(from))).go();
        await into(mobiliers).insert(
          MobiliersCompanion.insert(
            resourceId: to,
            uniteEnregistrementId: listRow.uniteEnregistrementId,
            displayCode: listRow.displayCode,
            typeLabel: Value(listRow.typeLabel),
            collectionDate: Value(listRow.collectionDate),
            syncedAt: DateTime.now(),
          ),
        );
      }

      final detailRow = await mobilierDetailRow(from);
      if (detailRow != null) {
        await (delete(mobiliersDetail)
              ..where((d) => d.resourceId.equals(from)))
            .go();
        final decoded = jsonDecode(detailRow.fieldsJson);
        final fieldsRaw = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : const <String, dynamic>{};
        await replaceMobilierDetailFields(
          resourceId: to,
          uniteEnregistrementId: detailRow.uniteEnregistrementId,
          fieldsRaw: fieldsRaw,
        );
      }

      await (update(syncActions)..where((a) => a.localEntityId.equals(from)))
          .write(SyncActionsCompanion(localEntityId: Value(to)));
    });
  }

  Future<List<UniteEnregistrement>> recordingUnitsForProject(String projectId) {
    return (select(unitesEnregistrement)
          ..where((u) => u.projectId.equals(projectId))
          ..orderBy([(u) => OrderingTerm(expression: u.displayCode)]))
        .get();
  }

  Future<int> countRecordingUnitsForProject(String projectId) async {
    final expr = unitesEnregistrement.projectId.count();
    final query = selectOnly(unitesEnregistrement)
      ..addColumns([expr])
      ..where(unitesEnregistrement.projectId.equals(projectId));
    final row = await query.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<void> upsertRecordingUnit({
    required RecordingUnitItem item,
    required String projectId,
    int? typeConceptId,
  }) async {
    await into(unitesEnregistrement).insertOnConflictUpdate(
      companionFromRecordingUnitItem(
        item,
        projectId,
        typeConceptId: typeConceptId,
      ),
    );
  }

  Future<void> deleteRecordingUnitByResourceId(String resourceId) async {
    await transaction(() async {
      await (delete(unitesEnregistrement)
            ..where((u) => u.resourceId.equals(resourceId)))
          .go();
      await (delete(unitesEnregistrementDetail)
            ..where((d) => d.resourceId.equals(resourceId)))
          .go();
      await (delete(mobiliers)
            ..where((m) => m.uniteEnregistrementId.equals(resourceId)))
          .go();
      await (delete(documentsUniteEnregistrement)
            ..where((d) => d.uniteEnregistrementId.equals(resourceId)))
          .go();
    });
  }

  /// Supprime une UE du cache local (et éventuellement ses enfants locaux).
  Future<void> deleteRecordingUnitFromCache({
    required String resourceId,
    required bool cascadeChildren,
  }) async {
    final key = resourceId.trim();
    if (key.isEmpty) return;

    await transaction(() async {
      if (cascadeChildren) {
        final mobilierRows = await mobiliersForRecordingUnit(key);
        for (final row in mobilierRows) {
          await deleteMobilierByResourceId(row.resourceId);
        }

        final tmpRows = await documentTmpForRecordingUnit(key);
        for (final row in tmpRows) {
          await deleteDocumentTmp(row.localId);
        }
      }

      await (delete(entitySyncSnapshots)
            ..where(
              (s) =>
                  s.entityType.equals(SyncEntityType.recordingUnit) &
                  s.entityId.equals(key),
            ))
          .go();

      await deleteRecordingUnitByResourceId(key);
    });
  }

  Future<int> countDocumentsForRecordingUnit(String recordingUnitId) async {
    final expr = documentsUniteEnregistrement.uniteEnregistrementId.count();
    final query = selectOnly(documentsUniteEnregistrement)
      ..addColumns([expr])
      ..where(
        documentsUniteEnregistrement.uniteEnregistrementId.equals(
          recordingUnitId,
        ),
      );
    final row = await query.getSingleOrNull();
    return row?.read(expr) ?? 0;
  }

  /// Retire les actions outbox liées à une UE (y compris mobiliers en attente).
  Future<void> purgeOutboxForRecordingUnit(String recordingUnitId) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) return;

    final rows = await select(syncActions).get();
    for (final row in rows) {
      if (_syncActionReferencesRecordingUnit(row, key)) {
        await deleteSyncAction(row.actionId);
      }
    }
  }

  bool _syncActionReferencesRecordingUnit(
    SyncActionRow row,
    String recordingUnitId,
  ) {
    if (row.localEntityId == recordingUnitId ||
        row.serverEntityId == recordingUnitId) {
      return true;
    }

    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map) return false;
      final map = Map<String, dynamic>.from(decoded);
      if (map['recordingUnitId']?.toString() == recordingUnitId) return true;
      if (map['actionUnitId']?.toString() == recordingUnitId) return false;
    } catch (_) {}

    return false;
  }

  Future<void> replaceRecordingUnitDetail({
    required String resourceId,
    required String detailJson,
    int? typeConceptId,
  }) async {
    await into(unitesEnregistrementDetail).insertOnConflictUpdate(
      UnitesEnregistrementDetailCompanion.insert(
        resourceId: resourceId,
        detailJson: detailJson,
        typeConceptId: Value(typeConceptId),
        syncedAt: DateTime.now(),
      ),
    );
  }

  Future<UniteEnregistrementDetailRow?> recordingUnitDetailRow(
    String resourceId,
  ) {
    return (select(unitesEnregistrementDetail)
          ..where((d) => d.resourceId.equals(resourceId)))
        .getSingleOrNull();
  }

  static MobiliersCompanion companionFromMobilierItem(
    MobilierItem item,
    String uniteEnregistrementId,
  ) {
    return MobiliersCompanion.insert(
      resourceId: item.id,
      uniteEnregistrementId: uniteEnregistrementId,
      displayCode: item.displayCode,
      typeLabel: Value(item.typeLabel),
      collectionDate: Value(item.collectionDate),
      syncedAt: DateTime.now(),
    );
  }

  Future<void> replaceMobiliersForRecordingUnit({
    required String uniteEnregistrementId,
    required List<MobilierItem> items,
  }) async {
    final companions = items
        .where((m) => m.id.trim().isNotEmpty)
        .map((m) => companionFromMobilierItem(m, uniteEnregistrementId))
        .toList();

    final table = mobiliers;
    await transaction(() async {
      await (delete(table)
            ..where((m) => m.uniteEnregistrementId.equals(uniteEnregistrementId)))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, companions);
        });
      }
    });
  }

  Future<List<MobilierCache>> mobiliersForRecordingUnit(
    String uniteEnregistrementId,
  ) {
    return (select(mobiliers)
          ..where((m) => m.uniteEnregistrementId.equals(uniteEnregistrementId))
          ..orderBy([(m) => OrderingTerm(expression: m.displayCode)]))
        .get();
  }

  Future<MobilierCache?> mobilierListRow(String resourceId) {
    return (select(mobiliers)
          ..where((m) => m.resourceId.equals(resourceId.trim())))
        .getSingleOrNull();
  }

  Future<void> upsertMobilier({
    required MobilierItem item,
    required String uniteEnregistrementId,
  }) async {
    await into(mobiliers).insertOnConflictUpdate(
      companionFromMobilierItem(item, uniteEnregistrementId),
    );
  }

  Future<void> deleteMobilierByResourceId(String resourceId) async {
    await transaction(() async {
      await (delete(mobiliers)..where((m) => m.resourceId.equals(resourceId)))
          .go();
      await (delete(mobiliersDetail)
            ..where((d) => d.resourceId.equals(resourceId)))
          .go();
    });
  }

  Future<String?> projectIdForRecordingUnit(String recordingUnitId) async {
    final row = await recordingUnitListRow(recordingUnitId);
    return row?.projectId;
  }

  Future<UniteEnregistrement?> recordingUnitListRow(String recordingUnitId) {
    return (select(unitesEnregistrement)
          ..where((u) => u.resourceId.equals(recordingUnitId)))
        .getSingleOrNull();
  }

  Future<void> replaceMobilierDetailFields({
    required String resourceId,
    required String uniteEnregistrementId,
    required Map<String, dynamic> fieldsRaw,
  }) async {
    await into(mobiliersDetail).insertOnConflictUpdate(
      MobiliersDetailCompanion.insert(
        resourceId: resourceId,
        uniteEnregistrementId: uniteEnregistrementId,
        fieldsJson: jsonEncode(fieldsRaw),
        syncedAt: DateTime.now(),
      ),
    );
  }

  Future<MobilierDetailRow?> mobilierDetailRow(String resourceId) {
    return (select(mobiliersDetail)
          ..where((d) => d.resourceId.equals(resourceId)))
        .getSingleOrNull();
  }

  Future<Map<String, dynamic>?> mobilierDetailFieldsRaw(String resourceId) async {
    final row = await mobilierDetailRow(resourceId);
    if (row == null) return null;
    final decoded = jsonDecode(row.fieldsJson);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<String?> recordingUnitIdForMobilier(String mobilierId) async {
    final detail = await mobilierDetailRow(mobilierId.trim());
    if (detail != null && detail.uniteEnregistrementId.isNotEmpty) {
      return detail.uniteEnregistrementId;
    }
    final row = await (select(mobiliers)
          ..where((m) => m.resourceId.equals(mobilierId.trim())))
        .getSingleOrNull();
    return row?.uniteEnregistrementId;
  }

  Future<int> countCachedPlaces({required int organisationId}) async {
    final countExp = lieux.placeId.count();
    final query = selectOnly(lieux)
      ..addColumns([countExp])
      ..where(lieux.organisationId.equals(organisationId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> nextLocalPlaceId({required int organisationId}) async {
    final minExp = lieux.placeId.min();
    final query = selectOnly(lieux)
      ..addColumns([minExp])
      ..where(
        lieux.organisationId.equals(organisationId) &
            lieux.placeId.isSmallerThanValue(0),
      );
    final row = await query.getSingleOrNull();
    final currentMin = row?.read(minExp);
    if (currentMin == null || currentMin >= 0) return -1;
    return currentMin - 1;
  }

  Future<void> replaceCachedPlacesForOrganisation({
    required int organisationId,
    required List<({int placeId, String name, String? code})> places,
  }) async {
    final pendingDeletes = await pendingDeletePlaceIds(
      organisationId: organisationId,
    );
    await transaction(() async {
      await (delete(lieux)
            ..where(
              (l) =>
                  l.organisationId.equals(organisationId) &
                  l.pendingSync.equals(false) &
                  l.pendingDelete.equals(false),
            ))
          .go();
      final now = DateTime.now();
      for (final place in places) {
        if (pendingDeletes.contains(place.placeId)) continue;
        await into(lieux).insertOnConflictUpdate(
          LieuxCompanion.insert(
            placeId: place.placeId,
            organisationId: organisationId,
            name: place.name,
            code: Value(place.code),
            pendingSync: const Value(false),
            pendingDelete: const Value(false),
            syncedAt: now,
          ),
        );
      }
    });
  }

  Future<void> upsertCachedPlaces({
    required int organisationId,
    required List<({int placeId, String name, String? code})> places,
    required bool pendingSync,
    int? typeConceptId,
    String? addressJson,
    bool pendingDelete = false,
  }) async {
    final now = DateTime.now();
    for (final place in places) {
      await into(lieux).insertOnConflictUpdate(
        LieuxCompanion.insert(
          placeId: place.placeId,
          organisationId: organisationId,
          name: place.name,
          code: Value(place.code),
          pendingSync: Value(pendingSync),
          pendingDelete: Value(pendingDelete),
          typeConceptId: Value(typeConceptId),
          addressJson: Value(addressJson),
          syncedAt: now,
        ),
      );
    }
  }

  Future<void> upsertCachedPlace({
    required int organisationId,
    required int placeId,
    required String name,
    String? code,
    required bool pendingSync,
    bool pendingDelete = false,
    int? typeConceptId,
    String? addressJson,
  }) {
    return upsertCachedPlaces(
      organisationId: organisationId,
      places: [(placeId: placeId, name: name, code: code)],
      pendingSync: pendingSync,
      typeConceptId: typeConceptId,
      addressJson: addressJson,
      pendingDelete: pendingDelete,
    );
  }

  Future<void> deleteCachedPlace({
    required int organisationId,
    required int placeId,
  }) async {
    await (delete(lieux)
          ..where(
            (l) =>
                l.organisationId.equals(organisationId) &
                l.placeId.equals(placeId),
          ))
        .go();
  }

  Future<void> markCachedPlacePendingDelete({
    required int organisationId,
    required int placeId,
  }) async {
    await (update(lieux)
          ..where(
            (l) =>
                l.organisationId.equals(organisationId) &
                l.placeId.equals(placeId),
          ))
        .write(
      const LieuxCompanion(
        pendingDelete: Value(true),
        pendingSync: Value(true),
      ),
    );
  }

  Future<Set<int>> pendingDeletePlaceIds({
    required int organisationId,
  }) async {
    final rows = await (select(lieux)
          ..where(
            (l) =>
                l.organisationId.equals(organisationId) &
                l.pendingDelete.equals(true),
          ))
        .get();
    return rows.map((r) => r.placeId).toSet();
  }

  Future<
      ({
        int placeId,
        String name,
        String? code,
        bool pendingSync,
        bool pendingDelete,
        int? typeConceptId,
        String? addressJson,
      })?> cachedPlaceRow({
    required int organisationId,
    required int placeId,
  }) async {
    final row = await (select(lieux)
          ..where(
            (l) =>
                l.organisationId.equals(organisationId) &
                l.placeId.equals(placeId),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    return (
      placeId: row.placeId,
      name: row.name,
      code: row.code,
      pendingSync: row.pendingSync,
      pendingDelete: row.pendingDelete,
      typeConceptId: row.typeConceptId,
      addressJson: row.addressJson,
    );
  }

  Future<
      List<
          ({
            int placeId,
            String name,
            String? code,
            bool pendingSync,
            bool pendingDelete,
            int? typeConceptId,
            String? addressJson,
          })>> listCachedPlacesRaw({
    required int organisationId,
    String? query,
  }) async {
    final q = query?.trim().toLowerCase() ?? '';
    final rows = await (select(lieux)
          ..where(
            (l) =>
                l.organisationId.equals(organisationId) &
                l.pendingDelete.equals(false),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.name)]))
        .get();

    Iterable<LieuCache> filtered = rows;
    if (q.isNotEmpty) {
      filtered = rows.where((row) {
        final name = row.name.toLowerCase();
        final code = row.code?.toLowerCase() ?? '';
        return name.contains(q) || code.contains(q);
      });
    }

    return [
      for (final row in filtered)
        (
          placeId: row.placeId,
          name: row.name,
          code: row.code,
          pendingSync: row.pendingSync,
          pendingDelete: row.pendingDelete,
          typeConceptId: row.typeConceptId,
          addressJson: row.addressJson,
        ),
    ];
  }

  Future<
      List<
          ({
            int placeId,
            String name,
            String? code,
            bool pendingSync,
            bool pendingDelete,
            int? typeConceptId,
            String? addressJson,
          })>> searchCachedPlacesRaw({
    required int organisationId,
    required String query,
    int limit = 20,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    final all = await listCachedPlacesRaw(
      organisationId: organisationId,
      query: q,
    );
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  Future<void> remapCachedPlaceId({
    required int organisationId,
    required int fromPlaceId,
    required int toPlaceId,
    required String name,
    String? code,
  }) async {
    await transaction(() async {
      await (delete(lieux)
            ..where(
              (l) =>
                  l.organisationId.equals(organisationId) &
                  l.placeId.equals(fromPlaceId),
            ))
          .go();
      await into(lieux).insertOnConflictUpdate(
        LieuxCompanion.insert(
          placeId: toPlaceId,
          organisationId: organisationId,
          name: name,
          code: Value(code),
          pendingSync: const Value(false),
          syncedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> remapLocalPlaceIdInOutboxPayloads({
    required int fromPlaceId,
    required int toPlaceId,
  }) async {
    final rows = await (select(syncActions)
          ..where(
            (a) =>
                a.status.isIn(['pending', 'failed', 'conflict', 'uploading']),
          ))
        .get();

    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.payloadJson);
        if (decoded is! Map) continue;
        final map = Map<String, dynamic>.from(decoded);
        var changed = false;

        final fieldAnswers = map['fieldAnswers'];
        if (fieldAnswers is Map) {
          final fa = Map<String, dynamic>.from(fieldAnswers);
          for (final entry in fa.entries) {
            final v = entry.value;
            if (_matchesLocalPlaceId(v, fromPlaceId)) {
              fa[entry.key] = toPlaceId;
              changed = true;
            } else if (v is List) {
              final list = List<dynamic>.from(v);
              var listChanged = false;
              for (var i = 0; i < list.length; i++) {
                if (_matchesLocalPlaceId(list[i], fromPlaceId)) {
                  list[i] = toPlaceId;
                  listChanged = true;
                }
              }
              if (listChanged) {
                fa[entry.key] = list;
                changed = true;
              }
            }
          }
          if (changed) map['fieldAnswers'] = fa;
        }

        final spatialIds = map['spatialContextSpatialUnitIds'];
        if (spatialIds is List) {
          final list = List<dynamic>.from(spatialIds);
          var listChanged = false;
          for (var i = 0; i < list.length; i++) {
            if (_matchesLocalPlaceId(list[i], fromPlaceId)) {
              list[i] = toPlaceId;
              listChanged = true;
            }
          }
          if (listChanged) {
            map['spatialContextSpatialUnitIds'] = list;
            changed = true;
          }
        }

        if (!changed) continue;
        await (update(syncActions)..where((a) => a.actionId.equals(row.actionId)))
            .write(
          SyncActionsCompanion(
            payloadJson: Value(jsonEncode(map)),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } catch (_) {}
    }
  }

  static bool _matchesLocalPlaceId(dynamic raw, int fromPlaceId) {
    if (raw is int) return raw == fromPlaceId;
    if (raw is num) return raw.toInt() == fromPlaceId;
    return int.tryParse(raw?.toString() ?? '') == fromPlaceId;
  }
}
