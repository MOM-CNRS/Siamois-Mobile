import '../../features/auth/auth_models.dart';
import 'app_database.dart';

/// Persistance utilisateur / organisations après login API.
class LocalAuthStore {
  LocalAuthStore(this._db);

  final AppDatabase _db;

  Future<void> saveFromLoginResponse({
    required Map<String, dynamic> loginJson,
    required String email,
    required String password,
  }) async {
    final user = loginJson['user'];
    if (user is! Map<String, dynamic>) return;

    final prenom = (user['name'] as String?)?.trim() ?? '';
    final nom = (user['lastname'] as String?)?.trim() ?? '';
    final userEmail = (user['email'] as String?)?.trim() ?? email.trim();
    final username = _buildUsername(prenom, nom, userEmail);

    final orgs = _parseOrganisations(user['organizations']);
    if (orgs.isEmpty) {
      throw StateError('Aucune organisation dans la réponse de connexion.');
    }

    for (final org in orgs) {
      await _db.upsertOrganisation(id: org.id, nom: org.name);
    }

    await _db.upsertUtilisateur(
      nom: nom,
      prenom: prenom,
      email: userEmail,
      username: username,
      password: password,
      idOrganisation: orgs.first.id,
    );
  }

  Future<StoredAuthProfile?> authenticateOffline({
    required String email,
    required String password,
  }) async {
    final row = await _db.findUtilisateurByEmail(email.trim());
    if (row == null || row.password != password) return null;

    final org = await (_db.select(_db.organisations)
          ..where((o) => o.id.equals(row.idOrganisation)))
        .getSingleOrNull();

    return StoredAuthProfile(
      email: row.email,
      firstName: row.prenom,
      lastName: row.nom,
      username: row.username,
      primaryOrganizationId: row.idOrganisation,
      primaryOrganizationName: org?.nom,
      organizations: await _loadAllOrganisations(),
    );
  }

  /// Mot de passe enregistré localement (après une connexion en ligne).
  Future<String?> storedPasswordForEmail(String email) async {
    final row = await _db.findUtilisateurByEmail(email.trim());
    final pwd = row?.password;
    if (pwd == null || pwd.isEmpty) return null;
    return pwd;
  }

  Future<StoredAuthProfile?> profileFromLocalDb(String email) async {
    final row = await _db.findUtilisateurByEmail(email.trim());
    if (row == null) return null;

    final org = await (_db.select(_db.organisations)
          ..where((o) => o.id.equals(row.idOrganisation)))
        .getSingleOrNull();

    return StoredAuthProfile(
      email: row.email,
      firstName: row.prenom,
      lastName: row.nom,
      username: row.username,
      primaryOrganizationId: row.idOrganisation,
      primaryOrganizationName: org?.nom,
      organizations: await _loadAllOrganisations(),
    );
  }

  Future<List<StoredOrganization>> _loadAllOrganisations() async {
    final rows = await _db.allOrganisations();
    return rows
        .map((o) => StoredOrganization(id: o.id, name: o.nom))
        .toList();
  }

  static String _buildUsername(String prenom, String nom, String email) {
    final full = '$prenom $nom'.trim();
    if (full.isNotEmpty) return full;
    return email;
  }

  static List<StoredOrganization> _parseOrganisations(dynamic raw) {
    if (raw is! List) return const [];
    final out = <StoredOrganization>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final idRaw = map['id'];
      int? id;
      if (idRaw is int) {
        id = idRaw;
      } else if (idRaw is num) {
        id = idRaw.toInt();
      }
      if (id == null) continue;
      final name = (map['name'] as String?)?.trim() ?? 'Organisation $id';
      out.add(StoredOrganization(id: id, name: name));
    }
    return out;
  }
}
