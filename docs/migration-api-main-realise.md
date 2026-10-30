# Migration API Siamois `main` — ce qui a été fait

Branche : `fix/api-compat-main` (depuis `main` mobile, `9f76d7e`). Un commit par lot.
Référence serveur : `SIAMOIS/CODE/Siamois/docs/api-changes-vs-main.md`.

Objectif : l'appli mobile fonctionne contre le `/api/v1` refondu de Siamois `main`,
hors-ligne compris, avec les listes de vocabulaire **pré-chargées à la synchro**
par (projet, type, champ).

## Décisions validées

- Vocabulaires pré-chargés à la synchro, par (projet, type, champ).
- Synchro du thésaurus supprimée (l'écran était masqué).
- Une seule branche, un commit par lot.
- La branche `fix/legacy-form-endpoints-project-scoped` n'est pas touchée.

## Lot 1 — Endpoints cassés (`f79dd2f`)

| Avant | Maintenant |
|---|---|
| `/recording-units/{id}/mobiliers` | `/recording-units/{id}/finds` |
| `/organizations/{id}/places` | `GET /places?organizationId=&offset=&limit=` ; détail via `GET /places/{id}` |
| `projects/form` | `GET /organizations/{id}/project-types` (`form`/`fields` à la racine) |
| `addresses/autocomplete` | retiré, repli GeoPlateforme direct |
| `users?...` | paramètre `search` au lieu de `q` |
| `users/me/thesaurus` | retiré (étape de synchro, méthodes et service supprimés) |

- Phases paginées (`limit=100`) ; relations d'UE via `/relations` (parents + enfants),
  `/children` gardé en repli sur 404.

## Lot 2 — Contrat des réponses (`9d36550`)

- Ids en chaîne : helper unique `parseApiId`, colonnes Drift inchangées.
- Multi-valeurs `{values,total,complete}` lues dans le détail d'UE.
- `answerType` étendu au jeu fermé du serveur ; type inconnu = lecture seule.
- `validationStatus` lu (UE, mobiliers, projets) et affiché en badge.
- Erreurs `{error,message}` : `AuthException.code`, test `conflict` sur le code et non
  plus sur le texte.

## Lot 3 — Types par projet, vocabulaire par champ (`af7f25c`)

- Nouveaux appels : `GET /projects/{id}/{recording-unit|find|document}-types` et
  `GET /organizations/{id}/concepts?fieldId=&projectId=&valueConceptId=&q=`
  (200 max, total dans `X-Total-Count`).
- Cache dans la table `Forms` existante sous clés composites (**pas de migration Drift**) :
  `FormCacheType.typeCatalog`, `placeTypes`, `conceptsPrefix`, `fieldConcepts`.
- `VocabularyCache` réécrit : lecture par (projet, type) avec repli sur l'union de
  l'organisation. Le reste de l'appli consomme toujours
  `Map<String, List<ConceptOption>>` (clés `fieldCode` et `#fieldId`).
- Nouveau modèle `ProjectEntityType` (`lib/features/projects/form/project_entity_type.dart`).
- Ordre de synchro : lieux, annuaire, formulaires, projets, puis types et concepts
  (concurrence 4).
- Formulaires UE / mobilier construits depuis le catalogue du type ; `projectId` passé
  par les pages concernées.
- Supprimés : `/vocabularies`, `creation-form` et `finds/form` par type,
  `searchConceptAutocomplete`.

## Lot 4 — Écriture des réponses (`ff5848a`)

- Toutes les écritures envoient `answers: {fieldId: AnswerInput}` (`value` / `values` /
  `add` / `remove`).
- Conversion **à l'envoi** (`asAnswerInputs`) : les actions déjà en outbox
  (`fieldAnswers`) partent au bon format sans migration.
- Création de mobilier : un seul `POST /finds` avec `answers`.
- Création de projet : `POST /projects` sans réponses puis `PATCH`
  (`_applyProjectAnswers`).

## Correctifs après les lots

- `bdd6433` : suppression de la garde « ancienne URL siamois.mom.fr » ; l'URL
  `siamois.mom.fr/siamois` est acceptée.
- `25f356d` : les ids d'organisation en chaîne étaient ignorés au login
  (`LocalAuthStore._parseOrganisations`), d'où le faux « aucune organisation ».

## Tests

`test/api_contract/` : `project_types_test`, `vocabulary_cache_test`,
`answer_inputs_test`, `login_organizations_test`. Le gabarit `test/widget_test.dart` a
été supprimé.

## Limites connues

- `https://siamois2.mom.fr/siamois2` n'est pas sur `main` : « Réponse serveur
  illisible » sur `project-types`. Utiliser un serveur local ou à jour.
- `android/gradle.properties` modifié par le migrateur Flutter, non commité.
