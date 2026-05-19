import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/projects/project_detail_models.dart';
import '../../features/projects/project_models.dart';
import '../../features/projects/form/person_option.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
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
  UnitesEnregistrementDetail,
  SyncActions,
  EntitySyncSnapshots,
  Mobiliers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 9;

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

      await batch((b) {
        b.insertAll(
          utilisateurs,
          persons.map((p) => p.toCompanion(organisationId)).toList(),
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

  Future<void> replaceForm({
    required int organisationId,
    required String type,
    required String contenuJson,
    required int ttlDays,
  }) async {
    await (delete(forms)
          ..where(
            (f) =>
                f.idOrganisation.equals(organisationId) &
                f.type.equals(type),
          ))
        .go();
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

  Future<void> replaceProjectsForOrganisation({
    required int organisationId,
    required List<ProjectSummary> projects,
  }) async {
    final companions = <ProjetsCompanion>[];
    final seen = <String>{};
    for (final p in projects) {
      final key = p.storageId;
      if (!seen.add(key)) continue;
      companions.add(companionFromSummary(p, organisationId));
    }

    await transaction(() async {
      await (delete(projets)
            ..where((p) => p.idOrganisation.equals(organisationId)))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(projets, companions);
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

  Future<List<SyncActionRow>> pendingSyncActions() {
    return (select(syncActions)
          ..where(
            (a) => a.status.isIn(['pending', 'failed', 'conflict']),
          )
          ..orderBy([(a) => OrderingTerm(expression: a.sequence)]))
        .get();
  }

  Future<int> countPendingSyncActions() async {
    final rows = await (select(syncActions)
          ..where(
            (a) => a.status.isIn(['pending', 'failed', 'conflict']),
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

  Future<void> deleteSyncAction(String actionId) async {
    await (delete(syncActions)..where((a) => a.actionId.equals(actionId))).go();
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
      syncedAt: DateTime.now(),
    );
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
    await transaction(() async {
      await (delete(table)..where((u) => u.projectId.equals(projectId))).go();
      if (companions.isNotEmpty) {
        await batch((b) {
          b.insertAll(table, companions);
        });
      }
    });
  }

  Future<List<UniteEnregistrement>> recordingUnitsForProject(String projectId) {
    return (select(unitesEnregistrement)
          ..where((u) => u.projectId.equals(projectId))
          ..orderBy([(u) => OrderingTerm(expression: u.displayCode)]))
        .get();
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

  Future<void> upsertMobilier({
    required MobilierItem item,
    required String uniteEnregistrementId,
  }) async {
    await into(mobiliers).insertOnConflictUpdate(
      companionFromMobilierItem(item, uniteEnregistrementId),
    );
  }

  Future<void> deleteMobilierByResourceId(String resourceId) async {
    await (delete(mobiliers)..where((m) => m.resourceId.equals(resourceId))).go();
  }
}
