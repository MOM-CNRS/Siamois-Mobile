/// Organisation accessible à l’utilisateur.
class StoredOrganization {
  const StoredOrganization({required this.id, required this.name});

  final int id;
  final String name;
}

/// Profil utilisateur + organisations (cache local / session).
class StoredAuthProfile {
  const StoredAuthProfile({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.username,
    this.primaryOrganizationId,
    this.primaryOrganizationName,
    this.organizations = const [],
  });

  final String email;
  /// Prénom (champ JSON `name`).
  final String firstName;
  /// Nom (champ JSON `lastname`).
  final String lastName;
  /// Libellé affiché (nom complet ou e-mail).
  final String? username;
  final int? primaryOrganizationId;
  final String? primaryOrganizationName;
  final List<StoredOrganization> organizations;

  String get displayName {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return fullName.isNotEmpty ? fullName : email;
  }

  String get fullName => '$firstName $lastName'.trim();

  String oneLineSummaryWithOrg() {
    final n = displayName;
    final o = primaryOrganizationName?.trim();
    if (o != null && o.isNotEmpty) {
      return '$n · $o';
    }
    return n.isNotEmpty ? n : email;
  }

  /// Organisation seule (sans nom / prénom), pour le menu latéral.
  String? get organizationLine {
    final o = primaryOrganizationName?.trim();
    return o != null && o.isNotEmpty ? o : null;
  }

  static StoredAuthProfile? fromLoginJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) return null;

    final email = user['email'] as String? ?? '';
    final firstName = user['name'] as String? ?? '';
    final lastName = user['lastname'] as String? ?? '';
    final orgs = _parseOrganizations(user['organizations']);

    int? orgId;
    String? orgName;
    if (orgs.isNotEmpty) {
      orgId = orgs.first.id;
      orgName = orgs.first.name;
    }

    final username = _buildUsername(firstName, lastName, email);

    return StoredAuthProfile(
      email: email,
      firstName: firstName,
      lastName: lastName,
      username: username,
      primaryOrganizationId: orgId,
      primaryOrganizationName: orgName,
      organizations: orgs,
    );
  }

  static String _buildUsername(String first, String last, String email) {
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return email;
  }

  static List<StoredOrganization> _parseOrganizations(dynamic raw) {
    if (raw is! List) return const [];
    final out = <StoredOrganization>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final rawId = map['id'];
      int? id;
      if (rawId is int) {
        id = rawId;
      } else if (rawId is num) {
        id = rawId.toInt();
      }
      if (id == null) continue;
      final name = (map['name'] as String?)?.trim() ?? 'Organisation $id';
      out.add(StoredOrganization(id: id, name: name));
    }
    return out;
  }
}
