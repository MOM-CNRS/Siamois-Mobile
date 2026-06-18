# Siamois Mobile

Application Flutter pour la gestion de projets archéologiques sur terminaux mobiles (iOS, Android, macOS). Elle se connecte à l’API REST du backend [Siamois](https://github.com/) et fonctionne en ligne comme hors ligne grâce à un cache SQLite local.

## Fonctionnalités

- **Authentification** — connexion par identifiants, stockage sécurisé des tokens
- **Projets** — liste, fiche détaillée, édition, création
- **Unités d’enregistrement (UE)** — liste arborescente, fiche, formulaires, création hors ligne
- **Documents** — consultation, ajout, pré-téléchargement et envoi différé
- **Mobiliers** — liste et formulaires rattachés aux UE
- **Mode hors ligne** — cache local (Drift/SQLite), file d’attente de synchronisation, résolution de conflits
- **Paramètres** — URL du serveur configurable avant connexion

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) SDK ≥ 3.0
- Un serveur Siamois accessible (API `/api/v1/…`)
- Pour macOS : Xcode et CocoaPods
- Pour Android : Android SDK (émulateur ou appareil)

Vérifier l’installation :

```bash
flutter doctor
```

## Installation

```bash
git clone <url-du-depot> Siamois-Mobile
cd Siamois-Mobile
flutter pub get
```

### Génération du code Drift

Après modification des tables (`lib/core/database/tables.dart`) :

```bash
dart run build_runner build
```

## Lancement

```bash
# macOS
flutter run -d macos

# Liste des appareils disponibles
flutter devices
```

### URL du serveur

L’URL par défaut est définie dans `lib/core/config/server_config.dart` :

```dart
const String kSiamoisServerBaseUrl = 'https://siamois2.mom.fr/siamois2';
```

| Environnement | URL |
|---------------|-----|
| Production (défaut) | `https://siamois2.mom.fr/siamois2` |
| Développement local | `http://localhost:8099/siamois` (via **Paramètres serveur**) |

L’URL peut aussi être modifiée dans l’application (**Paramètres serveur**) avant la connexion.

## Structure du projet

```
lib/
├── app.dart                 # Point d’entrée MaterialApp
├── core/
│   ├── config/              # Configuration serveur
│   ├── database/            # Drift (SQLite), tables, migrations
│   ├── network/             # Connectivité
│   ├── sync/                # Orchestrateur, outbox, conflits
│   ├── theme/               # Charte graphique Siamois
│   └── widgets/             # Composants partagés
└── features/
    ├── auth/                # Connexion, tokens
    ├── projects/            # Projets, UE, documents, mobiliers
    ├── settings/            # Paramètres et serveur
    └── sync/                # File d’attente de synchronisation
```

## Dépendances principales

| Package | Rôle |
|---------|------|
| `dio` | Client HTTP vers l’API |
| `drift` / `drift_flutter` | Base SQLite locale |
| `flutter_secure_storage` | Stockage sécurisé des tokens |
| `connectivity_plus` | Détection réseau |
| `file_picker` / `image_picker` | Pièces jointes documents |

## Fichiers ignorés par Git

Le `.gitignore` exclut notamment :

- `.dart_tool/`, `build/` — artefacts de compilation
- `.flutter-plugins-dependencies` — généré automatiquement
- `flutter_*.png` — captures d’écran de debug à la racine
- `.env`, keystores — secrets et signatures

## Licence

Projet interne Siamois — usage réservé aux contributeurs autorisés.
