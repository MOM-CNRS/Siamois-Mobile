# Migration API Siamois `main` — ce qui reste à faire

Voir aussi `migration-api-main-realise.md`.

Ordre proposé : 1 (identifiants) → 2 (mesures, après précision du besoin) → 3 (validation
sur serveur réel) → le reste.

## 1. Règles d'identifiant et identifiants hors ligne

### Constat côté serveur

- Chaque catalogue de types (UE, mobilier, phase, document, contenant, étude) renvoie
  `identifierConfig { identifierFormat, minCode, maxCode }`
  (`RecordingUnitIdentifierConfig`, construit dans `RecordingUnitOpenApiService`).
- Le format mélange du texte fixe et des jetons : `ID_UA`, `ID_PARENT`, `NUM_PARENT`,
  `NUM_USPATIAL`, plus un compteur numérique. Le compteur est calculé par partition
  (par exemple par UE parente).
- Le serveur sait donner un aperçu sans réserver le numéro (`suggestFullIdentifier`).
  Pour les projets : `GET /projects/next-identifier?organizationId=`, qui renvoie
  `{identifier}` (null si l'organisation ne peut pas numéroter).
- Unicité dans le projet (contraintes `uk_*_project_identifier`). Un doublon renvoie
  un 409.
- L'identifiant choisi par l'utilisateur est un champ **racine** `identifier` du corps :
  `POST /recording-units`, `POST /finds`, et les PATCH (UE, mobilier, phase, contenant,
  document). Absent ou vide, le serveur le génère.

### Constat côté mobile

- `identifierConfig` n'est lu nulle part dans `lib/` : aucune proposition d'identifiant.
- Hors ligne, l'UE s'affiche « UE (hors ligne) » tant qu'aucun champ lié à `identifier`
  n'est rempli (`recording_unit_offline_create.dart`).
- `createRecordingUnit` n'envoie que `projectId`, `typeId` et `answers`
  (`auth_repository.dart`). L'identifiant saisi part dans `answers[fieldId]`.

### Hypothèse sur « les identifiants définis hors ligne ne restent pas »

Le serveur applique `answers` en mode « lenient » (il ignore ce qu'il ne reconnaît pas)
puis génère son propre identifiant : celui saisi sur le mobile est perdu à la synchro.
**À confirmer** en lisant le corps envoyé pour une UE créée hors ligne et l'identifiant
obtenu sur le serveur.

### Travail

- [ ] Reproduire et confirmer l'hypothèse ci-dessus.
- [ ] Envoyer `identifier` à la racine du corps (création et PATCH, UE et mobilier ;
      outbox incluse, conversion à l'envoi comme pour `asAnswerInputs`).
- [ ] Lire `identifierConfig` dans `ProjectEntityType.parseCatalog` et le mettre en cache
      avec le catalogue.
- [ ] Proposer un identifiant dans les formulaires de création.
- [ ] Gérer le 409 « identifiant déjà utilisé » à la synchro (laisser le serveur
      générer, ou demander un autre identifiant à l'utilisateur).
- [ ] Projets : appeler `GET /projects/next-identifier` quand on est en ligne.
- [ ] Test de contrat : corps de création avec `identifier` à la racine.

### Décision à prendre

Hors ligne, le compteur dépend de l'état du serveur et ne peut pas être garanti :

- soit **suggestion locale approximative** (`ID_UA` + compteur local), avec gestion du
  409 ;
- soit **aucune proposition hors ligne**, le serveur génère à la synchro (affichage
  provisoire « hors ligne »).

## 2. Mesures « à la volée »

État actuel : champ de mesure (valeur, unité, commentaire) dans
`form_measurement_value.dart` et `project_form_measurement_input.dart`. L'unité est
figée à `m` par défaut. Non vérifié : lecture de `constraints.units` du catalogue.

**Besoin à préciser** (à valider avec l'équipe avant de coder) :

- [ ] ajouter plusieurs mesures sur un même champ ?
- [ ] saisir une mesure directement dans la fiche, sans le formulaire complet ?
- [ ] choisir l'unité (liste issue de `constraints.units`) ?
- [ ] calculer ou convertir une valeur ?

## 3. Valider contre un vrai serveur `main`

Rien n'a encore tourné contre un serveur à jour. À faire dans un émulateur / simulateur
avec un Siamois `main` local (Android : `10.0.2.2`) :

- [ ] Connexion + synchro complète sans 404 dans les logs.
- [ ] Liste des mobiliers d'une UE, lieux, création de projet.
- [ ] Hors-ligne : synchro en ligne d'abord (cache TTL 1 jour), couper wifi + données,
      créer / modifier une UE et un mobilier, rétablir le réseau, vérifier l'envoi de
      l'outbox.
- [ ] Modifier un champ multi-valeurs et une mesure, vérifier dans l'interface web.

Hypothèses à vérifier sur le serveur :

- [ ] `fieldCode` `SIAAU.TYPE` sur le champ `type` d'un projet.
- [ ] Format de `GET /finds/{id}` (présence du layout).
- [ ] Les concepts dépendent-ils vraiment de `projectId` / `valueConceptId` ? (conditionne
      la dédup du point 4).

## 4. Volume d'appels à la synchro

La synchro fait projets × types × champs appels. Pistes, par ordre de rentabilité :

1. **Dédupliquer** les fetch de concepts par `vocabulary.source` (si la réponse ne
   dépend pas du projet / type).
2. **Chargement paresseux** : ne pré-charger que les projets ouverts récemment.
3. **ETag / 304** sur catalogues et concepts.
4. **Endpoint serveur dédié** `/sync/reference-data` (un appel par projet). Pour le
   réserver au mobile : un scope de jeton ou un en-tête client versionné, plutôt que de
   le cacher (la sécurité vient de l'authentification, pas de l'obscurité).
- [ ] Mesurer d'abord : compter les appels dans les logs avant d'optimiser.

## 5. Robustesse

- [ ] `_syncFormType` (`lib/core/sync/sync_orchestrator.dart`) n'est pas tolérant aux
      erreurs : un type en échec bloque la synchro. Le rendre non bloquant (log + suite).
- [ ] Repli pour serveurs anciens (anciens endpoints) : à décider, aujourd'hui l'appli
      vise uniquement `main`.
- [ ] Documents : `GET /documents/form` conservé ; vérifier la résolution des listes
      `SIAD.NATURE|SCALE|FORMAT` via `document-types.fields`.
- [ ] Multi-valeurs de plus de 200 éléments : vérifier que le complément
      `GET /{collection}/{id}/fields/{fieldId}/values` est bien en place.

## 6. Fonctionnalités serveur non utilisées par le mobile

Dans l'ordre d'intérêt supposé, à arbitrer :

- [ ] **Champs en lecture seule** : UE liée, document, adresse, mobilier, contenant,
      stratigraphie. Les rendre éditables si le terrain en a besoin.
- [ ] **Droits (`_permissions`)** : non lus. Un utilisateur sans droit voit les boutons
      et reçoit un 403 ; masquer les actions selon `_permissions` (et `canCreate` sur
      `GET /projects`).
- [ ] **Écriture de `validationStatus`** : le mobile l'affiche seulement.
- [ ] **Règles conditionnelles de champs** (branche serveur `feat/field-rules-engine`,
      `docs/regles-conditionnelles-champs.md`) : document non lu, impact à analyser.
- [ ] **Autres entités** : phases, contenants, études, documents complets
      (`POST /documents`), duplication d'UE (`duplicate-structure`) et de mobilier
      (`duplicate`), favoris.

## 7. Nettoyage et livraison

- [ ] Décider du sort de `android/gradle.properties` (commiter ou `git checkout`).
- [ ] Tests : ajouter des fixtures JSON capturées sur un serveur `main` (`/relations`,
      multi-valeurs incomplètes, corps d'erreur 409).
- [ ] `flutter analyze` et `flutter test` propres sur toute la branche.
- [ ] Préparer la PR `fix/api-compat-main` → `main` (ne rien pousser sans accord).

## Comment remplir / poursuivre la migration

Ordre conseillé pour un nouveau changement d'API :

1. Lire `docs/api-changes-vs-main.md` côté serveur, lister les endpoints et contrats
   touchés.
2. Adapter les appels dans `lib/features/auth/auth_repository.dart` (toute la surface
   API y est).
3. Si un format de cache change, préférer une clé composite dans la table `Forms`
   (`lib/core/database/tables.dart`) plutôt qu'une migration Drift.
4. Ajouter un test de contrat dans `test/api_contract/` avec un JSON réel.
5. Un commit par lot, `flutter analyze` + `flutter test` avant chaque commit.
