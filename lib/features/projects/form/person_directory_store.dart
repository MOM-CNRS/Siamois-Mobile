import '../../../core/database/app_database.dart';
import '../../auth/auth_models.dart';
import '../../auth/auth_repository.dart';
import 'person_option.dart';

/// Annuaire personnes : cache SQLite (`utilisateurs`) ou API `/users`.
class PersonDirectoryStore {
  PersonDirectoryStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get _isOnline => _auth.canUseProjectsApi();

  /// Recherche pour autocomplétion (cache + API + utilisateur connecté).
  Future<PersonSearchResult> search({
    required int organizationId,
    required String query,
  }) async {
    final local = await _allCandidates(organizationId);
    final filteredLocal = _filter(local, query);

    if (!await _isOnline) {
      return PersonSearchResult(items: filteredLocal, fromCache: true);
    }

    try {
      final remote = query.trim().isEmpty
          ? await _auth.fetchAllOrganizationUsers(
              organizationId: organizationId,
            )
          : (await _auth.fetchOrganizationUsers(
              organizationId: organizationId,
              search: query.trim(),
              offset: 0,
              limit: 100,
            ))
              .items;

      final merged = _mergePeople([
        ...remote,
        ...local,
      ]);
      final items = _filter(merged, query);
      return PersonSearchResult(
        items: items,
        fromCache: remote.isEmpty,
      );
    } on AuthException {
      return PersonSearchResult(items: filteredLocal, fromCache: true);
    }
  }

  Future<List<PersonOption>> _allFromCache(int organizationId) async {
    final rows = await _db.directoryPersonsForOrganisation(organizationId);
    return rows.map(PersonOption.fromUtilisateurRow).toList();
  }

  Future<List<PersonOption>> _allCandidates(int organizationId) async {
    return _mergePeople([
      ...await _allFromCache(organizationId),
      if (_connectedUserOption(organizationId) != null)
        _connectedUserOption(organizationId)!,
    ]);
  }

  static List<PersonOption> mergeForOrganization({
    required List<PersonOption> remote,
    required StoredAuthProfile? profile,
    required int organizationId,
  }) {
    final connected = _connectedUserFromProfile(profile, organizationId);
    return _mergePeople([
      ...remote,
      if (connected != null) connected,
    ]);
  }

  static PersonOption? _connectedUserFromProfile(
    StoredAuthProfile? profile,
    int organizationId,
  ) {
    if (profile == null) return null;
    final belongsToOrg = profile.primaryOrganizationId == organizationId ||
        profile.organizations.any((org) => org.id == organizationId);
    if (!belongsToOrg) return null;
    final personId = profile.personId;
    if (personId == null) return null;
    return PersonOption(
      id: personId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email,
      username: profile.username,
    );
  }

  PersonOption? _connectedUserOption(int organizationId) =>
      _connectedUserFromProfile(_auth.userProfile, organizationId);

  /// Annuaire indexé par `apiPersonId` pour l’affichage (auteurs, contributeurs…).
  Future<Map<int, PersonOption>> loadDirectoryByIdMap(int organizationId) async {
    final all = await _allCandidates(organizationId);
    return {for (final p in all) p.id: p};
  }

  /// Cache local, puis API si vide (pour résoudre les id → nom/prénom).
  Future<Map<int, PersonOption>> ensureDirectoryByIdMap(
    int organizationId,
  ) async {
    var map = await loadDirectoryByIdMap(organizationId);
    if (map.isNotEmpty) return map;
    if (!await _isOnline) return map;

    try {
      final remote = await _auth.fetchAllOrganizationUsers(
        organizationId: organizationId,
      );
      if (remote.isEmpty) {
        return map;
      }

      await _db.replaceDirectoryPersonsForOrganisation(
        organisationId: organizationId,
        persons: remote.map(DirectoryPersonInput.fromPersonOption).toList(),
      );
      map = await loadDirectoryByIdMap(organizationId);
      return map;
    } on AuthException {
      return map;
    }
  }

  static List<PersonOption> _mergePeople(List<PersonOption> people) {
    final byId = <int, PersonOption>{};
    for (final person in people) {
      final existing = byId[person.id];
      if (existing == null) {
        byId[person.id] = person;
        continue;
      }
      if (!existing.hasDisplayName && person.hasDisplayName) {
        byId[person.id] = person;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.display.compareTo(b.display));
    return merged;
  }

  static List<PersonOption> _filter(List<PersonOption> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) => p.matchesQuery(q)).toList();
  }
}

class PersonSearchResult {
  const PersonSearchResult({
    required this.items,
    required this.fromCache,
  });

  final List<PersonOption> items;
  final bool fromCache;
}
