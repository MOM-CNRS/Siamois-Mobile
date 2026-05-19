import 'package:drift/drift.dart';

/// Types de lignes dans [Forms].
abstract final class FormCacheType {
  static const vocabulaire = 'VOCABULAIRE';
  static const projet = 'PROJET';
  static const document = 'DOCUMENT';
  static const mobilier = 'MOBILIER';

  /// Formulaire de création UE pour un concept de type (`SIARU.TYPE`).
  static String typeUe(int typeConceptId) => 'TYPE_UE_$typeConceptId';
}

class Organisations extends Table {
  IntColumn get id => integer()();
  TextColumn get nom => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Utilisateurs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant API (`PersonDTO.id`) pour l’annuaire ; null = compte de connexion local.
  IntColumn get apiPersonId => integer().nullable()();

  TextColumn get nom => text()();
  TextColumn get prenom => text()();
  TextColumn get email => text().unique()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  IntColumn get idOrganisation => integer().references(Organisations, #id)();
}

class Forms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get contenu => text()();
  IntColumn get ttl => integer()();
  DateTimeColumn get creationDate => dateTime()();
  IntColumn get idOrganisation =>
      integer().references(Organisations, #id)();
}

class Projets extends Table {
  TextColumn get id => text()();
  TextColumn get nom => text()();
  TextColumn get identifiant => text().nullable()();
  TextColumn get fullIdentifier => text().nullable()();
  IntColumn get recordingUnitCount => integer().nullable()();
  IntColumn get idOrganisation =>
      integer().references(Organisations, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id, idOrganisation};
}

/// Détail projet sérialisé (réponse GET /projects/{id}).
@DataClassName('ProjetDetailRow')
class ProjetsDetail extends Table {
  TextColumn get resourceId => text()();
  TextColumn get detailJson => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}

/// Documents rattachés à un projet (cache offline).
class Documents extends Table {
  TextColumn get resourceId => text()();
  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get fileCode => text().nullable()();
  TextColumn get projectId => text()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}

/// Documents rattachés à une unité d'enregistrement (cache offline).
@DataClassName('DocumentUniteEnregistrement')
class DocumentsUniteEnregistrement extends Table {
  TextColumn get resourceId => text()();
  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get fileCode => text().nullable()();
  TextColumn get uniteEnregistrementId => text()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}

/// Unités d'enregistrement d'un projet (cache offline).
@DataClassName('UniteEnregistrement')
class UnitesEnregistrement extends Table {
  TextColumn get resourceId => text()();
  TextColumn get projectId => text()();
  TextColumn get displayCode => text()();
  TextColumn get identifier => text().nullable()();
  TextColumn get typeLabel => text().nullable()();
  TextColumn get placeLabel => text().nullable()();
  DateTimeColumn get openingDate => dateTime().nullable()();
  DateTimeColumn get closingDate => dateTime().nullable()();
  TextColumn get matrixColor => text().nullable()();
  IntColumn get specimenCount => integer().nullable()();
  IntColumn get stratigraphicCount => integer().nullable()();
  IntColumn get typeConceptId => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}

/// Détail UE sérialisé (réponse GET /recording-units/{id}).
@DataClassName('UniteEnregistrementDetailRow')
class UnitesEnregistrementDetail extends Table {
  TextColumn get resourceId => text()();
  TextColumn get detailJson => text()();
  IntColumn get typeConceptId => integer().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}

/// Fichiers binaires locaux : pré-téléchargement ou en attente d’envoi serveur.
@DataClassName('DocumentTmpRow')
class DocumentsTmp extends Table {
  /// Identifiant local (UUID).
  TextColumn get localId => text()();

  /// Identifiant API une fois synchronisé (ou pour le cache pré-téléchargé).
  TextColumn get resourceId => text().nullable()();

  /// `project` ou `recording_unit`.
  TextColumn get parentType => text()();

  TextColumn get parentId => text()();

  /// `prefetch` (téléchargé pour consultation) ou `pending_upload` (créé hors ligne).
  TextColumn get kind => text()();

  /// `pending`, `uploading`, `synced`, `failed`.
  TextColumn get status => text()();

  TextColumn get titre => text()();
  TextColumn get description => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get fileCode => text().nullable()();
  TextColumn get url => text().nullable()();

  IntColumn get natureConceptId => integer().nullable()();
  IntColumn get scaleConceptId => integer().nullable()();
  IntColumn get formatConceptId => integer().nullable()();

  /// Contenu binaire du fichier.
  BlobColumn get fileContent => blob()();

  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get uploadError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

/// File d’attente des mutations à envoyer au serveur (outbox).
@DataClassName('SyncActionRow')
class SyncActions extends Table {
  TextColumn get actionId => text()();
  IntColumn get sequence => integer()();
  TextColumn get operation => text()();
  TextColumn get entityType => text()();
  TextColumn get localEntityId => text().nullable()();
  TextColumn get serverEntityId => text().nullable()();
  TextColumn get parentType => text().nullable()();
  TextColumn get parentLocalId => text().nullable()();
  TextColumn get parentServerId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get blobRef => text().nullable()();
  IntColumn get baseServerRevision => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {actionId};
}

/// Snapshot serveur au chargement d’une entité (détection de conflit).
@DataClassName('EntitySyncSnapshotRow')
class EntitySyncSnapshots extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get baseServerRevision => integer().withDefault(const Constant(0))();
  TextColumn get snapshotJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId};
}

/// Mobiliers rattachés à une UE (cache offline).
@DataClassName('MobilierCache')
class Mobiliers extends Table {
  TextColumn get resourceId => text()();
  TextColumn get uniteEnregistrementId => text()();
  TextColumn get displayCode => text()();
  TextColumn get typeLabel => text().nullable()();
  DateTimeColumn get collectionDate => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {resourceId};
}
