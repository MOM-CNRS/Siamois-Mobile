import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';
import '../../auth/auth_repository.dart';
import 'person_option.dart';

/// Annuaire personnes : cache SQLite (`utilisateurs`) ou API `/users`.
class PersonDirectoryStore {
  PersonDirectoryStore({
    required AuthRepository auth,
    required AppDatabase db,
    ConnectivityService? connectivity,
  })  : _auth = auth,
        _db = db,
        _connectivity = connectivity ?? auth.connectivity;

  final AuthRepository _auth;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  Future<bool> get _isOnline async {
    final base = _auth.lastUsedBaseUrl;
    if (base.isEmpty) return false;
    return _connectivity.isOnline(base);
  }

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

  static List<PersonOption> _filter(List<PersonOption> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (p) =>
              p.display.toLowerCase().contains(q) ||
              (p.email?.toLowerCase().contains(q) ?? false) ||
              (p.username?.toLowerCase().contains(q) ?? false),
        )
        .toList();
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
