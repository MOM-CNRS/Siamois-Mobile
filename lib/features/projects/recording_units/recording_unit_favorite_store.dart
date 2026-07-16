import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';

/// Favoris UE locaux (appareil), indépendants du cache sync.
class RecordingUnitFavoriteStore {
  RecordingUnitFavoriteStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  String get _userKey {
    final personId = _auth.userProfile?.personId;
    if (personId != null) return 'person:$personId';
    final email = _auth.userProfile?.email.trim();
    if (email != null && email.isNotEmpty) return 'email:$email';
    return 'local';
  }

  Future<Set<String>> favoriteIdsForProject(String projectId) async {
    final key = _userKey;
    final project = projectId.trim();
    final rows = await (_db.select(_db.unitesEnregistrementFavorites)
          ..where(
            (f) => f.userKey.equals(key) & f.projectId.equals(project),
          ))
        .get();
    return rows.map((r) => r.resourceId).toSet();
  }

  Future<bool> isFavorite({
    required String projectId,
    required String resourceId,
  }) async {
    final key = _userKey;
    final row = await (_db.select(_db.unitesEnregistrementFavorites)
          ..where(
            (f) =>
                f.userKey.equals(key) &
                f.resourceId.equals(resourceId.trim()) &
                f.projectId.equals(projectId.trim()),
          ))
        .getSingleOrNull();
    return row != null;
  }

  /// Bascule le favori. Retourne `true` si désormais favori.
  Future<bool> toggle({
    required String projectId,
    required String resourceId,
  }) async {
    final key = _userKey;
    final project = projectId.trim();
    final id = resourceId.trim();
    if (id.isEmpty || project.isEmpty) return false;

    final existing = await (_db.select(_db.unitesEnregistrementFavorites)
          ..where(
            (f) => f.userKey.equals(key) & f.resourceId.equals(id),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.delete(_db.unitesEnregistrementFavorites)
            ..where(
              (f) => f.userKey.equals(key) & f.resourceId.equals(id),
            ))
          .go();
      return false;
    }

    await _db.into(_db.unitesEnregistrementFavorites).insert(
          UnitesEnregistrementFavoritesCompanion.insert(
            userKey: key,
            resourceId: id,
            projectId: project,
            createdAt: DateTime.now(),
          ),
        );
    return true;
  }
}
