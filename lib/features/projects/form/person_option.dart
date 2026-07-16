import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'project_form_models.dart';

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

  bool get hasDisplayName =>
      lastName.trim().isNotEmpty || firstName.trim().isNotEmpty;

  /// Affichage : « NOM Prénom » (nom en majuscules, prénom avec 1re lettre seulement).
  String get display {
    final nom = lastName.trim().toUpperCase();
    final prenom = formatFirstName(firstName);
    if (nom.isEmpty && prenom.isEmpty) return '';
    if (nom.isEmpty) return prenom;
    if (prenom.isEmpty) return nom;
    return '$nom $prenom';
  }

  /// Affichage détaillé : « Prénom Nom · email ».
  String get detailDisplay {
    final prenom = formatFirstName(firstName);
    final nom = lastName.trim();
    final parts = <String>[];
    if (prenom.isNotEmpty) parts.add(prenom);
    if (nom.isNotEmpty) parts.add(nom);
    final name = parts.join(' ').trim();
    final mail = email?.trim();
    if (name.isNotEmpty && mail != null && mail.isNotEmpty) {
      return '$name · $mail';
    }
    if (name.isNotEmpty) return name;
    if (mail != null && mail.isNotEmpty) return mail;
    return '';
  }

  /// Prénom : première lettre en majuscule, le reste en minuscules.
  static String formatFirstName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.length == 1) return t.toUpperCase();
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return display.toLowerCase().contains(q) ||
        lastName.toLowerCase().contains(q) ||
        firstName.toLowerCase().contains(q) ||
        (email?.toLowerCase().contains(q) ?? false) ||
        (username?.toLowerCase().contains(q) ?? false);
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
      firstName: _string(json['name']) ??
          _string(json['firstName']) ??
          _string(json['prenom']) ??
          _string(json['label']) ??
          '',
      lastName: _string(json['lastname']) ??
          _string(json['lastName']) ??
          _string(json['nom']) ??
          '',
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
    if (raw is String) {
      final id = int.tryParse(raw.trim());
      if (id == null) return null;
      return PersonOption(
        id: id,
        firstName: '',
        lastName: '',
      );
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final attributes = map['attributes'];
    if (attributes is Map) {
      final merged = Map<String, dynamic>.from(attributes);
      final id = map['id'] ?? map['resourceId'];
      if (id != null) merged['id'] = id;
      return fromDynamic(merged);
    }

    final data = map['data'];
    if (data is Map) return fromDynamic(data);

    try {
      return PersonOption.fromJson(map);
    } catch (_) {
      final id = _parseInt(map['id'] ?? map['resourceId']);
      if (id == null) return null;
      return PersonOption(
        id: id,
        firstName: _string(map['name']) ?? _string(map['prenom']) ?? '',
        lastName: _string(map['lastname']) ??
            _string(map['nom']) ??
            _string(map['lastName']) ??
            '',
        email: _string(map['email']),
        username: _string(map['username']),
      );
    }
  }

  static List<PersonOption> listFromDynamic(dynamic raw) {
    if (raw == null) return const [];

    final entries = _unwrapEntries(raw);
    if (entries != null && entries.isNotEmpty) {
      return entries.map(fromDynamic).whereType<PersonOption>().toList();
    }

    if (raw is Map) {
      final single = fromDynamic(raw);
      return single != null ? [single] : const [];
    }

    final single = fromDynamic(raw);
    return single != null ? [single] : const [];
  }

  static List<dynamic>? _unwrapEntries(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is List) return data;
    if (data is Map) return [data];
    final items = map['items'];
    if (items is List) return items;
    return null;
  }

  /// Résout une personne (id seul, objet API ou annuaire local).
  static PersonOption? resolve(
    dynamic raw, {
    Map<int, PersonOption>? directoryById,
  }) {
    final id = extractId(raw);
    if (id != null && directoryById != null) {
      final fromDirectory = directoryById[id];
      if (fromDirectory != null) return fromDirectory;
    }

    final parsed = fromDynamic(raw);
    if (parsed == null) return null;
    if (parsed.hasDisplayName || (parsed.email?.trim().isNotEmpty ?? false)) {
      return parsed;
    }
    if (directoryById != null) {
      return directoryById[parsed.id];
    }
    return parsed;
  }

  /// Extrait l’identifiant personne depuis un id brut ou un objet API.
  static int? extractId(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) {
      final nested = extractId(data);
      if (nested != null) return nested;
    }
    return _parseInt(map['id'] ?? map['resourceId']);
  }

  /// Met à jour les champs personne du formulaire avec l’annuaire (id → nom/prénom).
  static void enrichFormPersonFields(
    ProjectFormState state,
    ProjectFormDefinition definition,
    Map<int, PersonOption> directoryById,
  ) {
    if (directoryById.isEmpty) return;

    for (final field in definition.fields) {
      switch (field.normalizedType) {
        case ProjectAnswerType.selectOnePerson:
          final current = state.personSingleValues[field.key];
          final resolved = resolve(current, directoryById: directoryById);
          if (resolved != null) {
            state.personSingleValues[field.key] = resolved;
          }
        case ProjectAnswerType.selectMultiplePerson:
          final current = state.personMultiValues[field.key];
          if (current == null || current.isEmpty) continue;
          final resolved = <PersonOption>[];
          for (final person in current) {
            final item = resolve(person, directoryById: directoryById);
            if (item != null) resolved.add(item);
          }
          state.personMultiValues[field.key] = resolved;
        default:
          break;
      }
    }
  }

  static String? resolveDisplay(
    dynamic raw, {
    Map<int, PersonOption>? directoryById,
  }) {
    final person = resolve(raw, directoryById: directoryById);
    if (person != null) {
      final label = person.detailDisplay;
      if (label.isNotEmpty) return label;
      if (person.hasDisplayName) return person.display;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return _string(map['displayLabel']) ??
          _string(map['label']) ??
          _string(map['name']);
    }
    return null;
  }

  static String? resolveDisplayList(
    dynamic raw, {
    Map<int, PersonOption>? directoryById,
  }) {
    final entries = _unwrapEntries(raw) ?? (raw is List ? raw : null);
    if (entries == null || entries.isEmpty) return null;
    final labels = <String>[];
    for (final entry in entries) {
      final label = resolveDisplay(entry, directoryById: directoryById);
      if (label != null && label.isNotEmpty) labels.add(label);
    }
    return labels.isEmpty ? null : labels.join('\n');
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

    final items = <PersonOption>[];

    void addEntry(dynamic entry) {
      final person = PersonOption.fromDynamic(entry);
      if (person != null) items.add(person);
    }

    void addFromList(List<dynamic> list) {
      for (final entry in list) {
        addEntry(entry);
      }
    }

    void addFromMap(Map<String, dynamic> map) {
      for (final key in const ['items', 'users', 'content', 'results']) {
        final raw = map[key];
        if (raw is List) {
          addFromList(raw);
          return;
        }
      }
      addEntry(map);
    }

    final data = body['data'];
    if (data is List) {
      addFromList(data);
    } else if (data is Map) {
      addFromMap(Map<String, dynamic>.from(data));
    }

    final topItems = body['items'];
    if (items.isEmpty && topItems is List) {
      addFromList(topItems);
    }

    final meta = body['meta'];
    int? total;
    int offset = 0;
    int limit = 100;
    if (meta is Map) {
      final m = Map<String, dynamic>.from(meta);
      total = _parseInt(m['total'] ?? m['totalElements'] ?? m['count']);
      offset = _parseInt(m['offset']) ?? 0;
      limit = _parseInt(m['limit'] ?? m['pageSize']) ?? 100;
    } else if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      total = _parseInt(m['total'] ?? m['totalElements'] ?? m['count']);
      offset = _parseInt(m['offset']) ?? 0;
      limit = _parseInt(m['limit'] ?? m['pageSize']) ?? 100;
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
