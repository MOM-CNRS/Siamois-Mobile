# Plan de migration — cache vocabulaire par projet

## Contexte

Aujourd'hui, le mobile télécharge le vocabulaire d'une organisation via
`GET /api/v1/organizations/{id}/vocabularies` et le met en cache dans la table
Drift `forms`, indexée uniquement par `(idOrganisation, type)` — voir
[`lib/core/database/tables.dart:39-47`](../lib/core/database/tables.dart) et
[`lib/core/database/app_database.dart:390-406`](../lib/core/database/app_database.dart).

Ce cache ne connaît pas la notion de projet. Or le backend expose (ou va
exposer, voir prérequis ci-dessous) des vocabulaires **surchargés par projet**
via `GET /api/v1/projects/{id}/field-codes` et
`GET /api/v1/projects/{id}/concepts?fieldCode=…`. Sans évolution du cache
local, deux projets d'une même organisation avec des vocabulaires personnalisés
différents écraseraient la même ligne de cache — le dernier synchronisé
gagnerait pour tout le monde, y compris hors ligne.

Ce document décrit comment faire évoluer le stockage et le requêtage du cache
vocabulaire pour qu'il devienne **par projet** (avec repli sur l'organisation
quand un projet n'a pas de surcharge), sans casser les autres usages de la
table `forms` (formulaires UE/mobilier par type, réglages thésaurus,
document/projet).

## Prérequis côté backend (bloquant, à valider avant de commencer)

Ces deux points ont été identifiés lors de l'audit de cohérence API — sans eux,
migrer le cache mobile vers un modèle par projet n'apporte aucun bénéfice
fonctionnel :

1. `VocabularyOpenApiService.getConceptsForOrganization` (appelé par
   `GET /projects/{id}/concepts`) résout toujours via l'institution, pas via
   `actionUnitId` — les surcharges de vocabulaire par projet
   (`ConceptFieldConfigRepository.findOneByFieldCodeAndActionUnitId`) ne sont
   donc pas encore appliquées par cet endpoint. Il faut brancher `actionUnitId`
   dans la chaîne d'appel.
2. Le mode pagination (`GET /concepts` sans `q`) repose sur
   `FieldConfigurationService.fetchAutocomplete` qui plafonne à
   `LIMIT_RESULTS = 200` concepts **avant** pagination — au-delà de 200
   concepts pour un field_code donné, la pagination renvoie silencieusement une
   liste vide. Ce plafond doit être levé (ou remplacé par une vraie requête
   paginée en base) pour ce mode d'usage.

## Format cible côté mobile

Deux options ont été évaluées.

### Option A — clé composite dans la colonne `type` existante (retenue)

Le projet a déjà une convention pour encoder une sous-dimension dans la colonne
`type` sans migration de schéma : `FormCacheType.typeUe(id)` produit
`TYPE_UE_<id>` pour les gabarits de formulaire UE par type
([`tables.dart:10-14`](../lib/core/database/tables.dart)). On applique la même
convention au vocabulaire :

```dart
abstract final class FormCacheType {
  static const vocabulaire = 'VOCABULAIRE'; // conservé : repli organisation
  ...
  /// Vocabulaire surchargé pour un projet donné.
  static String vocabulaireProjet(String projetId) =>
      'VOCABULAIRE_PROJET_$projetId';
}
```

**Avantages** : aucune migration de schéma Drift, aucun changement de la
table `forms`, réutilise le mécanisme `(idOrganisation, type)` déjà indexé et
déjà couvert par `pruneOrganisationsExcept`/`clearOfflineCache`
(ces méthodes filtrent par `idOrganisation`, donc continuent à tout purger
correctement même avec des clés `type` supplémentaires).

**Limite acceptée** : pas de colonne dédiée interrogeable ("donne-moi tous les
caches vocabulaire du projet X" reste une requête par préfixe de chaîne, pas un
`WHERE idProjet = X` typé). Acceptable ici car l'accès se fait toujours via une
clé `(orgId, type)` connue à l'avance par l'appelant (jamais de requête libre
sur "tous les projets").

### Option B — nouvelle colonne `idProjet` (écartée pour cette itération)

Ajouter une colonne `idProjet TEXT NULL` à `forms` avec clé unique
`(idOrganisation, idProjet, type)`. Plus "propre" relationnellement, mais :

- `Projets.id` est `TEXT` (pas `INT`) avec clé primaire composite
  `(id, idOrganisation)` ([`tables.dart:49-60`](../lib/core/database/tables.dart)) —
  une vraie FK Drift vers `Projets` demanderait de dupliquer `idOrganisation`
  dans `forms` pour la FK composite, ce qui alourdit toutes les requêtes
  existantes sur `forms` (formulaires UE/mobilier/document/projet qui n'ont
  pas de notion de projet).
- Exige une migration `schemaVersion` avec `ALTER TABLE` + tables temporaires
  (comme la migration `thesaurus_settings_v13`, voir
  [`app_database.dart:97-121`](../lib/core/database/app_database.dart)) pour
  gérer la contrainte d'unicité composite sous SQLite.
- Aucun bénéfice supplémentaire réel pour l'usage actuel (pas de requête
  transversale "tous les projets" prévue dans le produit).

→ Recommandation : partir sur l'**option A**, et ne basculer vers l'option B
que si un besoin de requêtage transversal par projet apparaît plus tard.

## Étapes de migration

### 1. Backend (prérequis, cf. section ci-dessus)
- [ ] Brancher `actionUnitId` dans `VocabularyOpenApiService.getConceptsForOrganization`
      → `FieldConfigurationService.fetchAutocomplete(info, fieldCode, q, actionUnitId)`.
- [ ] Lever/adapter le plafond `LIMIT_RESULTS = 200` pour le mode pagination
      (sans `q`) de `GET /projects/{id}/concepts`.
- [ ] Vérifier que `GET /projects/{id}/field-codes` reflète bien les
      field_codes surchargés au niveau projet (pas seulement institution).

### 2. Mobile — nouvelle clé de cache
- [ ] Ajouter `FormCacheType.vocabulaireProjet(String projetId)` dans
      [`lib/core/database/tables.dart`](../lib/core/database/tables.dart).
- [ ] Documenter dans le commentaire de `Forms` que `type` peut désormais
      encoder un projet pour le vocabulaire, comme c'est déjà le cas pour
      `TYPE_UE_*` / `TYPE_MOBILIER_*`.

### 3. Mobile — récupération réseau
- [ ] Dans `lib/features/auth/auth_repository.dart`, ajouter une méthode
      `fetchProjectVocabulariesRaw({required String projectId})` qui :
      1. Appelle `GET /api/v1/projects/{id}/field-codes`.
      2. Pour chaque `fieldCode`, appelle `GET /api/v1/projects/{id}/concepts?fieldCode=…`
         en paginant (`offset`/`limit`) jusqu'à épuisement.
      3. Réassemble chaque `ResolvedConceptResource` plat
         (`id`, `resolvedLabel`, `externalUrl`, `altLabels`, `definition`)
         dans la forme imbriquée déjà attendue par
         `ConceptOption._parseRawEntry` (`conceptLabelToDisplay.concept.{id,externalId}`,
         `conceptLabelToDisplay.label`) — voir
         [`lib/features/projects/vocabulary_models.dart:301`](../lib/features/projects/vocabulary_models.dart).
      4. Renvoie la même enveloppe `{data: {organizationId, fieldCodes, vocabulariesByFieldCode}}`
         que `fetchVocabulariesRaw` aujourd'hui, pour que rien en aval n'ait à
         changer de format.
- [ ] **Aucun changement requis** dans `ConceptOption`, `VocabularyCache`,
      `thesaurus_settings_service.dart` ni les écrans de formulaire : ils ne
      lisent que `data.vocabulariesByFieldCode`, peu importe comment elle a
      été assemblée.

### 4. Mobile — écriture en cache
- [ ] Dans `sync_orchestrator.dart`, à côté de `_downloadAndCacheVocabularies`
      (org), ajouter `_downloadAndCacheProjectVocabularies(project)` qui
      appelle `fetchProjectVocabulariesRaw` puis
      `_db.replaceForm(organisationId: org.id, type: FormCacheType.vocabulaireProjet(project.id), …)`.
- [ ] Décider de la politique de repli : si un projet n'a **aucune**
      surcharge (`field-codes` vide ou identique à l'organisation), ne pas
      créer d'entrée `VOCABULAIRE_PROJET_*` et laisser la lecture retomber sur
      `VOCABULAIRE` (org) — évite de dupliquer inutilement tout le vocabulaire
      organisation pour chaque projet sans surcharge.

### 5. Mobile — lecture en cache
- [ ] Étendre `VocabularyCache.loadByFieldCode` (ou ajouter
      `loadByFieldCodeForProject`) pour accepter `projetId` optionnel :
      1. Chercher `forms` avec `type = VOCABULAIRE_PROJET_<projetId>`.
      2. Si absent, repli sur `type = VOCABULAIRE` (comportement actuel).
- [ ] Mettre à jour les appelants qui connaissent déjà le projet courant
      (écrans de formulaire UE/mobilier, `recording_unit_form_cache.dart`,
      `mobilier_form_cache.dart`) pour passer le `projetId` à cette nouvelle
      méthode plutôt qu'à `VocabularyCache.loadByFieldCode(organisationId:)`.
- [ ] Les appelants qui n'ont pas de contexte projet (réglages thésaurus,
      annuaire) continuent d'utiliser le cache organisation tel quel.

### 6. Purge / invalidation
- [ ] Vérifier que `pruneOrganisationsExcept` et `clearOfflineCache`
      (`app_database.dart:157-174` et `278-325`) suppriment bien toutes les
      lignes `forms` d'une organisation, y compris les nouvelles clés
      `VOCABULAIRE_PROJET_*` — c'est déjà le cas car ces méthodes filtrent sur
      `idOrganisation` sans filtrer sur `type`, donc **aucun changement requis**
      ici.
- [ ] Ajouter la purge des entrées `VOCABULAIRE_PROJET_*` d'un projet
      supprimé/inaccessible (actuellement il n'existe pas de suppression
      ciblée par projet dans `forms` — à ajouter si l'app gère le retrait d'un
      projet du périmètre utilisateur sans purger toute l'organisation).

### 7. Tests
- [ ] Test Drift : deux projets de la même organisation avec des
      `vocabulariesByFieldCode` différents cohabitent sans écrasement.
- [ ] Test de repli : projet sans surcharge → lecture retombe bien sur le
      cache organisation.
- [ ] Test de réassemblage : `ResolvedConceptResource` plat → forme imbriquée
      attendue par `ConceptOption`, avec dédoublonnage par `externalId`
      toujours correct (`ConceptOption._dedupeByConceptExternalId`).
- [ ] Test de pagination réseau : boucle `offset/limit` sur
      `/projects/{id}/concepts` s'arrête bien quand une page renvoie moins que
      `limit` résultats (protection contre boucle infinie si le backend
      renvoie un total incohérent).

## Hors périmètre de ce plan

- Le passage à l'option B (colonne dédiée) si un besoin de requêtage
  transversal par projet apparaît.
- La suppression de `GET /organizations/{id}/vocabularies` côté backend —
  elle reste nécessaire tant que des écrans mobile n'ont pas de contexte
  projet (réglages thésaurus, annuaire).
