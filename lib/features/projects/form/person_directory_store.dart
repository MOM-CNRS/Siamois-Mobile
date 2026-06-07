import '../../../core/database/app_database.dart';
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

  /// Recherche pour autocomplétion (cache d’abord, API si en ligne).
  Future<PersonSearchResult> search({
    required int organizationId,
    required String query,
  }) async {
    final cached = _filter(
      await _allFromCache(organizationId),
      query,
    );
    if (!await _isOnline) {
      return PersonSearchResult(items: cached, fromCache: true);
    }

    try {
      final remote = await _auth.fetchOrganizationUsers(
        organizationId: organizationId,
        search: query.trim().isEmpty ? null : query.trim(),
        offset: 0,
        limit: 50,
      );
      final items = query.trim().isEmpty
          ? remote.items
          : _filter(remote.items, query);
      if (items.isNotEmpty) {
        return PersonSearchResult(items: items, fromCache: false);
      }
      return PersonSearchResult(items: cached, fromCache: cached.isNotEmpty);
    } on AuthException {
      return PersonSearchResult(items: cached, fromCache: true);
    }
  }

  Future<List<PersonOption>> _allFromCache(int organizationId) async {
    final rows = await _db.directoryPersonsForOrganisation(organizationId);
    return rows.map(PersonOption.fromUtilisateurRow).toList();
  }

  /// Annuaire indexé par `apiPersonId` pour l’affichage (auteurs, contributeurs…).
  Future<Map<int, PersonOption>> loadDirectoryByIdMap(int organizationId) async {
    final all = await _allFromCache(organizationId);
    return {for (final p in all) p.id: p};
  }

  /// Cache local, puis API si vide (pour résoudre les id → nom/prénom).
  Future<Map<int, PersonOption>> ensureDirectoryByIdMap(
    int organizationId,
  ) async {
    final cached = await loadDirectoryByIdMap(organizationId);
    if (cached.isNotEmpty) return cached;
    if (!await _isOnline) return cached;

    try {
      final remote = await _auth.fetchAllOrganizationUsers(
        organizationId: organizationId,
      );
      if (remote.isEmpty) return cached;

      await _db.replaceDirectoryPersonsForOrganisation(
        organisationId: organizationId,
        persons: remote.map(DirectoryPersonInput.fromPersonOption).toList(),
      );
      return {for (final p in remote) p.id: p};
    } on AuthException {
      return cached;
    }
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
