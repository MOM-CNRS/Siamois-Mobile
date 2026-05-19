import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Personne de l’annuaire organisation (API / cache `utilisateurs`).
class PersonOption {
  const PersonOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.username,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? username;

  String get display {
    final name = '$firstName $lastName'.trim();
    if (name.isEmpty) {
      return email ?? username ?? 'Personne $id';
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty && !name.contains(mail)) {
      return '$name ($mail)';
    }
    return name;
  }

  factory PersonOption.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['resourceId'];
    int? id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    } else {
      id = int.tryParse(idRaw?.toString() ?? '');
    }
    if (id == null) {
      throw FormatException('Identifiant personne invalide.');
    }

    return PersonOption(
      id: id,
      firstName: _string(json['name']) ?? '',
      lastName: _string(json['lastname']) ?? '',
      email: _string(json['email']),
      username: _string(json['username']),
    );
  }

  factory PersonOption.fromUtilisateurRow(Utilisateur row) {
    final apiId = row.apiPersonId;
    if (apiId == null) {
      throw StateError('Ligne utilisateur sans apiPersonId.');
    }
    final email = row.email.contains('@annuaire.local')
        ? (row.username.contains('@') ? row.username : null)
        : row.email;

    return PersonOption(
      id: apiId,
      firstName: row.prenom,
      lastName: row.nom,
      email: email,
      username: row.username,
    );
  }

  static PersonOption? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      return PersonOption(
        id: raw.toInt(),
        firstName: '',
        lastName: '',
      );
    }
    if (raw is Map) {
      try {
        return PersonOption.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        final id = _parseInt(raw['id']);
        if (id == null) return null;
        return PersonOption(
          id: id,
          firstName: _string(raw['name']) ?? '',
          lastName: _string(raw['lastname']) ?? '',
          email: _string(raw['email']),
        );
      }
    }
    return null;
  }

  static List<PersonOption> listFromDynamic(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(fromDynamic).whereType<PersonOption>().toList();
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Page `GET /api/v1/users`.
class OrganizationUsersResult {
  const OrganizationUsersResult({
    required this.items,
    this.total,
    this.offset = 0,
    this.limit = 100,
  });

  final List<PersonOption> items;
  final int? total;
  final int offset;
  final int limit;

  static OrganizationUsersResult fromJson(Map<String, dynamic>? body) {
    if (body == null) {
      return const OrganizationUsersResult(items: []);
    }

    final data = body['data'];
    final items = <PersonOption>[];

    void addFromList(List<dynamic> list) {
      for (final entry in list) {
        if (entry is Map) {
          try {
            items.add(
              PersonOption.fromJson(Map<String, dynamic>.from(entry)),
            );
          } catch (_) {}
        }
      }
    }

    if (data is List) {
      addFromList(data);
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final rawItems = map['items'] ?? map['users'] ?? map['content'];
      if (rawItems is List) {
        addFromList(rawItems);
      }
    }

    final meta = body['meta'];
    int? total;
    int offset = 0;
    int limit = 100;
    if (meta is Map) {
      final m = Map<String, dynamic>.from(meta);
      total = _parseInt(m['total']);
      offset = _parseInt(m['offset']) ?? 0;
      limit = _parseInt(m['limit']) ?? 100;
    }

    return OrganizationUsersResult(
      items: items,
      total: total,
      offset: offset,
      limit: limit,
    );
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

/// Entrée annuaire à persister dans [Utilisateurs].
class DirectoryPersonInput {
  const DirectoryPersonInput({
    required this.apiPersonId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.username,
  });

  final int apiPersonId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? username;

  factory DirectoryPersonInput.fromPersonOption(PersonOption option) {
    return DirectoryPersonInput(
      apiPersonId: option.id,
      firstName: option.firstName,
      lastName: option.lastName,
      email: option.email,
      username: option.username,
    );
  }

  UtilisateursCompanion toCompanion(int organisationId) {
    final uniqueEmail = '$apiPersonId@annuaire.local';
    final login = username?.trim();
    final mail = email?.trim();

    return UtilisateursCompanion(
      apiPersonId: Value(apiPersonId),
      nom: Value(lastName.trim().isNotEmpty ? lastName.trim() : '—'),
      prenom: Value(firstName.trim().isNotEmpty ? firstName.trim() : '—'),
      email: Value(uniqueEmail),
      username: Value(
        login != null && login.isNotEmpty
            ? login
            : (mail != null && mail.isNotEmpty ? mail : uniqueEmail),
      ),
      password: const Value(''),
      idOrganisation: Value(organisationId),
    );
  }
}
