// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OrganisationsTable extends Organisations
    with TableInfo<$OrganisationsTable, Organisation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganisationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
      'nom', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, nom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organisations';
  @override
  VerificationContext validateIntegrity(Insertable<Organisation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nom')) {
      context.handle(
          _nomMeta, nom.isAcceptableOrUnknown(data['nom']!, _nomMeta));
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Organisation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Organisation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nom'])!,
    );
  }

  @override
  $OrganisationsTable createAlias(String alias) {
    return $OrganisationsTable(attachedDatabase, alias);
  }
}

class Organisation extends DataClass implements Insertable<Organisation> {
  final int id;
  final String nom;
  const Organisation({required this.id, required this.nom});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nom'] = Variable<String>(nom);
    return map;
  }

  OrganisationsCompanion toCompanion(bool nullToAbsent) {
    return OrganisationsCompanion(
      id: Value(id),
      nom: Value(nom),
    );
  }

  factory Organisation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Organisation(
      id: serializer.fromJson<int>(json['id']),
      nom: serializer.fromJson<String>(json['nom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nom': serializer.toJson<String>(nom),
    };
  }

  Organisation copyWith({int? id, String? nom}) => Organisation(
        id: id ?? this.id,
        nom: nom ?? this.nom,
      );
  Organisation copyWithCompanion(OrganisationsCompanion data) {
    return Organisation(
      id: data.id.present ? data.id.value : this.id,
      nom: data.nom.present ? data.nom.value : this.nom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Organisation(')
          ..write('id: $id, ')
          ..write('nom: $nom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Organisation && other.id == this.id && other.nom == this.nom);
}

class OrganisationsCompanion extends UpdateCompanion<Organisation> {
  final Value<int> id;
  final Value<String> nom;
  const OrganisationsCompanion({
    this.id = const Value.absent(),
    this.nom = const Value.absent(),
  });
  OrganisationsCompanion.insert({
    this.id = const Value.absent(),
    required String nom,
  }) : nom = Value(nom);
  static Insertable<Organisation> custom({
    Expression<int>? id,
    Expression<String>? nom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nom != null) 'nom': nom,
    });
  }

  OrganisationsCompanion copyWith({Value<int>? id, Value<String>? nom}) {
    return OrganisationsCompanion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganisationsCompanion(')
          ..write('id: $id, ')
          ..write('nom: $nom')
          ..write(')'))
        .toString();
  }
}

class $UtilisateursTable extends Utilisateurs
    with TableInfo<$UtilisateursTable, Utilisateur> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UtilisateursTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _apiPersonIdMeta =
      const VerificationMeta('apiPersonId');
  @override
  late final GeneratedColumn<int> apiPersonId = GeneratedColumn<int>(
      'api_person_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
      'nom', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prenomMeta = const VerificationMeta('prenom');
  @override
  late final GeneratedColumn<String> prenom = GeneratedColumn<String>(
      'prenom', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idOrganisationMeta =
      const VerificationMeta('idOrganisation');
  @override
  late final GeneratedColumn<int> idOrganisation = GeneratedColumn<int>(
      'id_organisation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organisations (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, apiPersonId, nom, prenom, email, username, password, idOrganisation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'utilisateurs';
  @override
  VerificationContext validateIntegrity(Insertable<Utilisateur> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('api_person_id')) {
      context.handle(
          _apiPersonIdMeta,
          apiPersonId.isAcceptableOrUnknown(
              data['api_person_id']!, _apiPersonIdMeta));
    }
    if (data.containsKey('nom')) {
      context.handle(
          _nomMeta, nom.isAcceptableOrUnknown(data['nom']!, _nomMeta));
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('prenom')) {
      context.handle(_prenomMeta,
          prenom.isAcceptableOrUnknown(data['prenom']!, _prenomMeta));
    } else if (isInserting) {
      context.missing(_prenomMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('id_organisation')) {
      context.handle(
          _idOrganisationMeta,
          idOrganisation.isAcceptableOrUnknown(
              data['id_organisation']!, _idOrganisationMeta));
    } else if (isInserting) {
      context.missing(_idOrganisationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Utilisateur map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Utilisateur(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      apiPersonId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}api_person_id']),
      nom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nom'])!,
      prenom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prenom'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password'])!,
      idOrganisation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_organisation'])!,
    );
  }

  @override
  $UtilisateursTable createAlias(String alias) {
    return $UtilisateursTable(attachedDatabase, alias);
  }
}

class Utilisateur extends DataClass implements Insertable<Utilisateur> {
  final int id;

  /// Identifiant API (`PersonDTO.id`) pour l’annuaire ; null = compte de connexion local.
  final int? apiPersonId;
  final String nom;
  final String prenom;
  final String email;
  final String username;
  final String password;
  final int idOrganisation;
  const Utilisateur(
      {required this.id,
      this.apiPersonId,
      required this.nom,
      required this.prenom,
      required this.email,
      required this.username,
      required this.password,
      required this.idOrganisation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || apiPersonId != null) {
      map['api_person_id'] = Variable<int>(apiPersonId);
    }
    map['nom'] = Variable<String>(nom);
    map['prenom'] = Variable<String>(prenom);
    map['email'] = Variable<String>(email);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['id_organisation'] = Variable<int>(idOrganisation);
    return map;
  }

  UtilisateursCompanion toCompanion(bool nullToAbsent) {
    return UtilisateursCompanion(
      id: Value(id),
      apiPersonId: apiPersonId == null && nullToAbsent
          ? const Value.absent()
          : Value(apiPersonId),
      nom: Value(nom),
      prenom: Value(prenom),
      email: Value(email),
      username: Value(username),
      password: Value(password),
      idOrganisation: Value(idOrganisation),
    );
  }

  factory Utilisateur.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Utilisateur(
      id: serializer.fromJson<int>(json['id']),
      apiPersonId: serializer.fromJson<int?>(json['apiPersonId']),
      nom: serializer.fromJson<String>(json['nom']),
      prenom: serializer.fromJson<String>(json['prenom']),
      email: serializer.fromJson<String>(json['email']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      idOrganisation: serializer.fromJson<int>(json['idOrganisation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'apiPersonId': serializer.toJson<int?>(apiPersonId),
      'nom': serializer.toJson<String>(nom),
      'prenom': serializer.toJson<String>(prenom),
      'email': serializer.toJson<String>(email),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'idOrganisation': serializer.toJson<int>(idOrganisation),
    };
  }

  Utilisateur copyWith(
          {int? id,
          Value<int?> apiPersonId = const Value.absent(),
          String? nom,
          String? prenom,
          String? email,
          String? username,
          String? password,
          int? idOrganisation}) =>
      Utilisateur(
        id: id ?? this.id,
        apiPersonId: apiPersonId.present ? apiPersonId.value : this.apiPersonId,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        email: email ?? this.email,
        username: username ?? this.username,
        password: password ?? this.password,
        idOrganisation: idOrganisation ?? this.idOrganisation,
      );
  Utilisateur copyWithCompanion(UtilisateursCompanion data) {
    return Utilisateur(
      id: data.id.present ? data.id.value : this.id,
      apiPersonId:
          data.apiPersonId.present ? data.apiPersonId.value : this.apiPersonId,
      nom: data.nom.present ? data.nom.value : this.nom,
      prenom: data.prenom.present ? data.prenom.value : this.prenom,
      email: data.email.present ? data.email.value : this.email,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      idOrganisation: data.idOrganisation.present
          ? data.idOrganisation.value
          : this.idOrganisation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Utilisateur(')
          ..write('id: $id, ')
          ..write('apiPersonId: $apiPersonId, ')
          ..write('nom: $nom, ')
          ..write('prenom: $prenom, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('idOrganisation: $idOrganisation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, apiPersonId, nom, prenom, email, username, password, idOrganisation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Utilisateur &&
          other.id == this.id &&
          other.apiPersonId == this.apiPersonId &&
          other.nom == this.nom &&
          other.prenom == this.prenom &&
          other.email == this.email &&
          other.username == this.username &&
          other.password == this.password &&
          other.idOrganisation == this.idOrganisation);
}

class UtilisateursCompanion extends UpdateCompanion<Utilisateur> {
  final Value<int> id;
  final Value<int?> apiPersonId;
  final Value<String> nom;
  final Value<String> prenom;
  final Value<String> email;
  final Value<String> username;
  final Value<String> password;
  final Value<int> idOrganisation;
  const UtilisateursCompanion({
    this.id = const Value.absent(),
    this.apiPersonId = const Value.absent(),
    this.nom = const Value.absent(),
    this.prenom = const Value.absent(),
    this.email = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.idOrganisation = const Value.absent(),
  });
  UtilisateursCompanion.insert({
    this.id = const Value.absent(),
    this.apiPersonId = const Value.absent(),
    required String nom,
    required String prenom,
    required String email,
    required String username,
    required String password,
    required int idOrganisation,
  })  : nom = Value(nom),
        prenom = Value(prenom),
        email = Value(email),
        username = Value(username),
        password = Value(password),
        idOrganisation = Value(idOrganisation);
  static Insertable<Utilisateur> custom({
    Expression<int>? id,
    Expression<int>? apiPersonId,
    Expression<String>? nom,
    Expression<String>? prenom,
    Expression<String>? email,
    Expression<String>? username,
    Expression<String>? password,
    Expression<int>? idOrganisation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apiPersonId != null) 'api_person_id': apiPersonId,
      if (nom != null) 'nom': nom,
      if (prenom != null) 'prenom': prenom,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (idOrganisation != null) 'id_organisation': idOrganisation,
    });
  }

  UtilisateursCompanion copyWith(
      {Value<int>? id,
      Value<int?>? apiPersonId,
      Value<String>? nom,
      Value<String>? prenom,
      Value<String>? email,
      Value<String>? username,
      Value<String>? password,
      Value<int>? idOrganisation}) {
    return UtilisateursCompanion(
      id: id ?? this.id,
      apiPersonId: apiPersonId ?? this.apiPersonId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      idOrganisation: idOrganisation ?? this.idOrganisation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (apiPersonId.present) {
      map['api_person_id'] = Variable<int>(apiPersonId.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (prenom.present) {
      map['prenom'] = Variable<String>(prenom.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (idOrganisation.present) {
      map['id_organisation'] = Variable<int>(idOrganisation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UtilisateursCompanion(')
          ..write('id: $id, ')
          ..write('apiPersonId: $apiPersonId, ')
          ..write('nom: $nom, ')
          ..write('prenom: $prenom, ')
          ..write('email: $email, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('idOrganisation: $idOrganisation')
          ..write(')'))
        .toString();
  }
}

class $FormsTable extends Forms with TableInfo<$FormsTable, Form> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contenuMeta =
      const VerificationMeta('contenu');
  @override
  late final GeneratedColumn<String> contenu = GeneratedColumn<String>(
      'contenu', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ttlMeta = const VerificationMeta('ttl');
  @override
  late final GeneratedColumn<int> ttl = GeneratedColumn<int>(
      'ttl', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _creationDateMeta =
      const VerificationMeta('creationDate');
  @override
  late final GeneratedColumn<DateTime> creationDate = GeneratedColumn<DateTime>(
      'creation_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _idOrganisationMeta =
      const VerificationMeta('idOrganisation');
  @override
  late final GeneratedColumn<int> idOrganisation = GeneratedColumn<int>(
      'id_organisation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organisations (id)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, contenu, ttl, creationDate, idOrganisation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'forms';
  @override
  VerificationContext validateIntegrity(Insertable<Form> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('contenu')) {
      context.handle(_contenuMeta,
          contenu.isAcceptableOrUnknown(data['contenu']!, _contenuMeta));
    } else if (isInserting) {
      context.missing(_contenuMeta);
    }
    if (data.containsKey('ttl')) {
      context.handle(
          _ttlMeta, ttl.isAcceptableOrUnknown(data['ttl']!, _ttlMeta));
    } else if (isInserting) {
      context.missing(_ttlMeta);
    }
    if (data.containsKey('creation_date')) {
      context.handle(
          _creationDateMeta,
          creationDate.isAcceptableOrUnknown(
              data['creation_date']!, _creationDateMeta));
    } else if (isInserting) {
      context.missing(_creationDateMeta);
    }
    if (data.containsKey('id_organisation')) {
      context.handle(
          _idOrganisationMeta,
          idOrganisation.isAcceptableOrUnknown(
              data['id_organisation']!, _idOrganisationMeta));
    } else if (isInserting) {
      context.missing(_idOrganisationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Form map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Form(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      contenu: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contenu'])!,
      ttl: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ttl'])!,
      creationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}creation_date'])!,
      idOrganisation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_organisation'])!,
    );
  }

  @override
  $FormsTable createAlias(String alias) {
    return $FormsTable(attachedDatabase, alias);
  }
}

class Form extends DataClass implements Insertable<Form> {
  final int id;
  final String type;
  final String contenu;
  final int ttl;
  final DateTime creationDate;
  final int idOrganisation;
  const Form(
      {required this.id,
      required this.type,
      required this.contenu,
      required this.ttl,
      required this.creationDate,
      required this.idOrganisation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['contenu'] = Variable<String>(contenu);
    map['ttl'] = Variable<int>(ttl);
    map['creation_date'] = Variable<DateTime>(creationDate);
    map['id_organisation'] = Variable<int>(idOrganisation);
    return map;
  }

  FormsCompanion toCompanion(bool nullToAbsent) {
    return FormsCompanion(
      id: Value(id),
      type: Value(type),
      contenu: Value(contenu),
      ttl: Value(ttl),
      creationDate: Value(creationDate),
      idOrganisation: Value(idOrganisation),
    );
  }

  factory Form.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Form(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      contenu: serializer.fromJson<String>(json['contenu']),
      ttl: serializer.fromJson<int>(json['ttl']),
      creationDate: serializer.fromJson<DateTime>(json['creationDate']),
      idOrganisation: serializer.fromJson<int>(json['idOrganisation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'contenu': serializer.toJson<String>(contenu),
      'ttl': serializer.toJson<int>(ttl),
      'creationDate': serializer.toJson<DateTime>(creationDate),
      'idOrganisation': serializer.toJson<int>(idOrganisation),
    };
  }

  Form copyWith(
          {int? id,
          String? type,
          String? contenu,
          int? ttl,
          DateTime? creationDate,
          int? idOrganisation}) =>
      Form(
        id: id ?? this.id,
        type: type ?? this.type,
        contenu: contenu ?? this.contenu,
        ttl: ttl ?? this.ttl,
        creationDate: creationDate ?? this.creationDate,
        idOrganisation: idOrganisation ?? this.idOrganisation,
      );
  Form copyWithCompanion(FormsCompanion data) {
    return Form(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      contenu: data.contenu.present ? data.contenu.value : this.contenu,
      ttl: data.ttl.present ? data.ttl.value : this.ttl,
      creationDate: data.creationDate.present
          ? data.creationDate.value
          : this.creationDate,
      idOrganisation: data.idOrganisation.present
          ? data.idOrganisation.value
          : this.idOrganisation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Form(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('contenu: $contenu, ')
          ..write('ttl: $ttl, ')
          ..write('creationDate: $creationDate, ')
          ..write('idOrganisation: $idOrganisation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, contenu, ttl, creationDate, idOrganisation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Form &&
          other.id == this.id &&
          other.type == this.type &&
          other.contenu == this.contenu &&
          other.ttl == this.ttl &&
          other.creationDate == this.creationDate &&
          other.idOrganisation == this.idOrganisation);
}

class FormsCompanion extends UpdateCompanion<Form> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> contenu;
  final Value<int> ttl;
  final Value<DateTime> creationDate;
  final Value<int> idOrganisation;
  const FormsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.contenu = const Value.absent(),
    this.ttl = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.idOrganisation = const Value.absent(),
  });
  FormsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String contenu,
    required int ttl,
    required DateTime creationDate,
    required int idOrganisation,
  })  : type = Value(type),
        contenu = Value(contenu),
        ttl = Value(ttl),
        creationDate = Value(creationDate),
        idOrganisation = Value(idOrganisation);
  static Insertable<Form> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? contenu,
    Expression<int>? ttl,
    Expression<DateTime>? creationDate,
    Expression<int>? idOrganisation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (contenu != null) 'contenu': contenu,
      if (ttl != null) 'ttl': ttl,
      if (creationDate != null) 'creation_date': creationDate,
      if (idOrganisation != null) 'id_organisation': idOrganisation,
    });
  }

  FormsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? contenu,
      Value<int>? ttl,
      Value<DateTime>? creationDate,
      Value<int>? idOrganisation}) {
    return FormsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      contenu: contenu ?? this.contenu,
      ttl: ttl ?? this.ttl,
      creationDate: creationDate ?? this.creationDate,
      idOrganisation: idOrganisation ?? this.idOrganisation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (contenu.present) {
      map['contenu'] = Variable<String>(contenu.value);
    }
    if (ttl.present) {
      map['ttl'] = Variable<int>(ttl.value);
    }
    if (creationDate.present) {
      map['creation_date'] = Variable<DateTime>(creationDate.value);
    }
    if (idOrganisation.present) {
      map['id_organisation'] = Variable<int>(idOrganisation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('contenu: $contenu, ')
          ..write('ttl: $ttl, ')
          ..write('creationDate: $creationDate, ')
          ..write('idOrganisation: $idOrganisation')
          ..write(')'))
        .toString();
  }
}

class $ProjetsTable extends Projets with TableInfo<$ProjetsTable, Projet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
      'nom', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _identifiantMeta =
      const VerificationMeta('identifiant');
  @override
  late final GeneratedColumn<String> identifiant = GeneratedColumn<String>(
      'identifiant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fullIdentifierMeta =
      const VerificationMeta('fullIdentifier');
  @override
  late final GeneratedColumn<String> fullIdentifier = GeneratedColumn<String>(
      'full_identifier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordingUnitCountMeta =
      const VerificationMeta('recordingUnitCount');
  @override
  late final GeneratedColumn<int> recordingUnitCount = GeneratedColumn<int>(
      'recording_unit_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idOrganisationMeta =
      const VerificationMeta('idOrganisation');
  @override
  late final GeneratedColumn<int> idOrganisation = GeneratedColumn<int>(
      'id_organisation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organisations (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nom,
        identifiant,
        fullIdentifier,
        recordingUnitCount,
        idOrganisation
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projets';
  @override
  VerificationContext validateIntegrity(Insertable<Projet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nom')) {
      context.handle(
          _nomMeta, nom.isAcceptableOrUnknown(data['nom']!, _nomMeta));
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('identifiant')) {
      context.handle(
          _identifiantMeta,
          identifiant.isAcceptableOrUnknown(
              data['identifiant']!, _identifiantMeta));
    }
    if (data.containsKey('full_identifier')) {
      context.handle(
          _fullIdentifierMeta,
          fullIdentifier.isAcceptableOrUnknown(
              data['full_identifier']!, _fullIdentifierMeta));
    }
    if (data.containsKey('recording_unit_count')) {
      context.handle(
          _recordingUnitCountMeta,
          recordingUnitCount.isAcceptableOrUnknown(
              data['recording_unit_count']!, _recordingUnitCountMeta));
    }
    if (data.containsKey('id_organisation')) {
      context.handle(
          _idOrganisationMeta,
          idOrganisation.isAcceptableOrUnknown(
              data['id_organisation']!, _idOrganisationMeta));
    } else if (isInserting) {
      context.missing(_idOrganisationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, idOrganisation};
  @override
  Projet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Projet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      nom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nom'])!,
      identifiant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifiant']),
      fullIdentifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_identifier']),
      recordingUnitCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}recording_unit_count']),
      idOrganisation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id_organisation'])!,
    );
  }

  @override
  $ProjetsTable createAlias(String alias) {
    return $ProjetsTable(attachedDatabase, alias);
  }
}

class Projet extends DataClass implements Insertable<Projet> {
  final String id;
  final String nom;
  final String? identifiant;
  final String? fullIdentifier;
  final int? recordingUnitCount;
  final int idOrganisation;
  const Projet(
      {required this.id,
      required this.nom,
      this.identifiant,
      this.fullIdentifier,
      this.recordingUnitCount,
      required this.idOrganisation});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nom'] = Variable<String>(nom);
    if (!nullToAbsent || identifiant != null) {
      map['identifiant'] = Variable<String>(identifiant);
    }
    if (!nullToAbsent || fullIdentifier != null) {
      map['full_identifier'] = Variable<String>(fullIdentifier);
    }
    if (!nullToAbsent || recordingUnitCount != null) {
      map['recording_unit_count'] = Variable<int>(recordingUnitCount);
    }
    map['id_organisation'] = Variable<int>(idOrganisation);
    return map;
  }

  ProjetsCompanion toCompanion(bool nullToAbsent) {
    return ProjetsCompanion(
      id: Value(id),
      nom: Value(nom),
      identifiant: identifiant == null && nullToAbsent
          ? const Value.absent()
          : Value(identifiant),
      fullIdentifier: fullIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(fullIdentifier),
      recordingUnitCount: recordingUnitCount == null && nullToAbsent
          ? const Value.absent()
          : Value(recordingUnitCount),
      idOrganisation: Value(idOrganisation),
    );
  }

  factory Projet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Projet(
      id: serializer.fromJson<String>(json['id']),
      nom: serializer.fromJson<String>(json['nom']),
      identifiant: serializer.fromJson<String?>(json['identifiant']),
      fullIdentifier: serializer.fromJson<String?>(json['fullIdentifier']),
      recordingUnitCount: serializer.fromJson<int?>(json['recordingUnitCount']),
      idOrganisation: serializer.fromJson<int>(json['idOrganisation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nom': serializer.toJson<String>(nom),
      'identifiant': serializer.toJson<String?>(identifiant),
      'fullIdentifier': serializer.toJson<String?>(fullIdentifier),
      'recordingUnitCount': serializer.toJson<int?>(recordingUnitCount),
      'idOrganisation': serializer.toJson<int>(idOrganisation),
    };
  }

  Projet copyWith(
          {String? id,
          String? nom,
          Value<String?> identifiant = const Value.absent(),
          Value<String?> fullIdentifier = const Value.absent(),
          Value<int?> recordingUnitCount = const Value.absent(),
          int? idOrganisation}) =>
      Projet(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        identifiant: identifiant.present ? identifiant.value : this.identifiant,
        fullIdentifier:
            fullIdentifier.present ? fullIdentifier.value : this.fullIdentifier,
        recordingUnitCount: recordingUnitCount.present
            ? recordingUnitCount.value
            : this.recordingUnitCount,
        idOrganisation: idOrganisation ?? this.idOrganisation,
      );
  Projet copyWithCompanion(ProjetsCompanion data) {
    return Projet(
      id: data.id.present ? data.id.value : this.id,
      nom: data.nom.present ? data.nom.value : this.nom,
      identifiant:
          data.identifiant.present ? data.identifiant.value : this.identifiant,
      fullIdentifier: data.fullIdentifier.present
          ? data.fullIdentifier.value
          : this.fullIdentifier,
      recordingUnitCount: data.recordingUnitCount.present
          ? data.recordingUnitCount.value
          : this.recordingUnitCount,
      idOrganisation: data.idOrganisation.present
          ? data.idOrganisation.value
          : this.idOrganisation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Projet(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('identifiant: $identifiant, ')
          ..write('fullIdentifier: $fullIdentifier, ')
          ..write('recordingUnitCount: $recordingUnitCount, ')
          ..write('idOrganisation: $idOrganisation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, nom, identifiant, fullIdentifier, recordingUnitCount, idOrganisation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Projet &&
          other.id == this.id &&
          other.nom == this.nom &&
          other.identifiant == this.identifiant &&
          other.fullIdentifier == this.fullIdentifier &&
          other.recordingUnitCount == this.recordingUnitCount &&
          other.idOrganisation == this.idOrganisation);
}

class ProjetsCompanion extends UpdateCompanion<Projet> {
  final Value<String> id;
  final Value<String> nom;
  final Value<String?> identifiant;
  final Value<String?> fullIdentifier;
  final Value<int?> recordingUnitCount;
  final Value<int> idOrganisation;
  final Value<int> rowid;
  const ProjetsCompanion({
    this.id = const Value.absent(),
    this.nom = const Value.absent(),
    this.identifiant = const Value.absent(),
    this.fullIdentifier = const Value.absent(),
    this.recordingUnitCount = const Value.absent(),
    this.idOrganisation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjetsCompanion.insert({
    required String id,
    required String nom,
    this.identifiant = const Value.absent(),
    this.fullIdentifier = const Value.absent(),
    this.recordingUnitCount = const Value.absent(),
    required int idOrganisation,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        nom = Value(nom),
        idOrganisation = Value(idOrganisation);
  static Insertable<Projet> custom({
    Expression<String>? id,
    Expression<String>? nom,
    Expression<String>? identifiant,
    Expression<String>? fullIdentifier,
    Expression<int>? recordingUnitCount,
    Expression<int>? idOrganisation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nom != null) 'nom': nom,
      if (identifiant != null) 'identifiant': identifiant,
      if (fullIdentifier != null) 'full_identifier': fullIdentifier,
      if (recordingUnitCount != null)
        'recording_unit_count': recordingUnitCount,
      if (idOrganisation != null) 'id_organisation': idOrganisation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? nom,
      Value<String?>? identifiant,
      Value<String?>? fullIdentifier,
      Value<int?>? recordingUnitCount,
      Value<int>? idOrganisation,
      Value<int>? rowid}) {
    return ProjetsCompanion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      identifiant: identifiant ?? this.identifiant,
      fullIdentifier: fullIdentifier ?? this.fullIdentifier,
      recordingUnitCount: recordingUnitCount ?? this.recordingUnitCount,
      idOrganisation: idOrganisation ?? this.idOrganisation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (identifiant.present) {
      map['identifiant'] = Variable<String>(identifiant.value);
    }
    if (fullIdentifier.present) {
      map['full_identifier'] = Variable<String>(fullIdentifier.value);
    }
    if (recordingUnitCount.present) {
      map['recording_unit_count'] = Variable<int>(recordingUnitCount.value);
    }
    if (idOrganisation.present) {
      map['id_organisation'] = Variable<int>(idOrganisation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjetsCompanion(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('identifiant: $identifiant, ')
          ..write('fullIdentifier: $fullIdentifier, ')
          ..write('recordingUnitCount: $recordingUnitCount, ')
          ..write('idOrganisation: $idOrganisation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjetsDetailTable extends ProjetsDetail
    with TableInfo<$ProjetsDetailTable, ProjetDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjetsDetailTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detailJsonMeta =
      const VerificationMeta('detailJson');
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
      'detail_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [resourceId, detailJson, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projets_detail';
  @override
  VerificationContext validateIntegrity(Insertable<ProjetDetailRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
          _detailJsonMeta,
          detailJson.isAcceptableOrUnknown(
              data['detail_json']!, _detailJsonMeta));
    } else if (isInserting) {
      context.missing(_detailJsonMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  ProjetDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjetDetailRow(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      detailJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}detail_json'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $ProjetsDetailTable createAlias(String alias) {
    return $ProjetsDetailTable(attachedDatabase, alias);
  }
}

class ProjetDetailRow extends DataClass implements Insertable<ProjetDetailRow> {
  final String resourceId;
  final String detailJson;
  final DateTime syncedAt;
  const ProjetDetailRow(
      {required this.resourceId,
      required this.detailJson,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['detail_json'] = Variable<String>(detailJson);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  ProjetsDetailCompanion toCompanion(bool nullToAbsent) {
    return ProjetsDetailCompanion(
      resourceId: Value(resourceId),
      detailJson: Value(detailJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory ProjetDetailRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjetDetailRow(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      detailJson: serializer.fromJson<String>(json['detailJson']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'detailJson': serializer.toJson<String>(detailJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  ProjetDetailRow copyWith(
          {String? resourceId, String? detailJson, DateTime? syncedAt}) =>
      ProjetDetailRow(
        resourceId: resourceId ?? this.resourceId,
        detailJson: detailJson ?? this.detailJson,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  ProjetDetailRow copyWithCompanion(ProjetsDetailCompanion data) {
    return ProjetDetailRow(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      detailJson:
          data.detailJson.present ? data.detailJson.value : this.detailJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjetDetailRow(')
          ..write('resourceId: $resourceId, ')
          ..write('detailJson: $detailJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, detailJson, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjetDetailRow &&
          other.resourceId == this.resourceId &&
          other.detailJson == this.detailJson &&
          other.syncedAt == this.syncedAt);
}

class ProjetsDetailCompanion extends UpdateCompanion<ProjetDetailRow> {
  final Value<String> resourceId;
  final Value<String> detailJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const ProjetsDetailCompanion({
    this.resourceId = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjetsDetailCompanion.insert({
    required String resourceId,
    required String detailJson,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        detailJson = Value(detailJson),
        syncedAt = Value(syncedAt);
  static Insertable<ProjetDetailRow> custom({
    Expression<String>? resourceId,
    Expression<String>? detailJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (detailJson != null) 'detail_json': detailJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjetsDetailCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? detailJson,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return ProjetsDetailCompanion(
      resourceId: resourceId ?? this.resourceId,
      detailJson: detailJson ?? this.detailJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjetsDetailCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('detailJson: $detailJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titreMeta = const VerificationMeta('titre');
  @override
  late final GeneratedColumn<String> titre = GeneratedColumn<String>(
      'titre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileCodeMeta =
      const VerificationMeta('fileCode');
  @override
  late final GeneratedColumn<String> fileCode = GeneratedColumn<String>(
      'file_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        resourceId,
        titre,
        description,
        fileName,
        mimeType,
        url,
        fileCode,
        projectId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<Document> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('titre')) {
      context.handle(
          _titreMeta, titre.isAcceptableOrUnknown(data['titre']!, _titreMeta));
    } else if (isInserting) {
      context.missing(_titreMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('file_code')) {
      context.handle(_fileCodeMeta,
          fileCode.isAcceptableOrUnknown(data['file_code']!, _fileCodeMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      titre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titre'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      fileCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_code']),
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final String resourceId;
  final String titre;
  final String? description;
  final String? fileName;
  final String? mimeType;
  final String? url;
  final String? fileCode;
  final String projectId;
  const Document(
      {required this.resourceId,
      required this.titre,
      this.description,
      this.fileName,
      this.mimeType,
      this.url,
      this.fileCode,
      required this.projectId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['titre'] = Variable<String>(titre);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || fileCode != null) {
      map['file_code'] = Variable<String>(fileCode);
    }
    map['project_id'] = Variable<String>(projectId);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      resourceId: Value(resourceId),
      titre: Value(titre),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      fileCode: fileCode == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCode),
      projectId: Value(projectId),
    );
  }

  factory Document.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      titre: serializer.fromJson<String>(json['titre']),
      description: serializer.fromJson<String?>(json['description']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      url: serializer.fromJson<String?>(json['url']),
      fileCode: serializer.fromJson<String?>(json['fileCode']),
      projectId: serializer.fromJson<String>(json['projectId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'titre': serializer.toJson<String>(titre),
      'description': serializer.toJson<String?>(description),
      'fileName': serializer.toJson<String?>(fileName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'url': serializer.toJson<String?>(url),
      'fileCode': serializer.toJson<String?>(fileCode),
      'projectId': serializer.toJson<String>(projectId),
    };
  }

  Document copyWith(
          {String? resourceId,
          String? titre,
          Value<String?> description = const Value.absent(),
          Value<String?> fileName = const Value.absent(),
          Value<String?> mimeType = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> fileCode = const Value.absent(),
          String? projectId}) =>
      Document(
        resourceId: resourceId ?? this.resourceId,
        titre: titre ?? this.titre,
        description: description.present ? description.value : this.description,
        fileName: fileName.present ? fileName.value : this.fileName,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        url: url.present ? url.value : this.url,
        fileCode: fileCode.present ? fileCode.value : this.fileCode,
        projectId: projectId ?? this.projectId,
      );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      titre: data.titre.present ? data.titre.value : this.titre,
      description:
          data.description.present ? data.description.value : this.description,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      url: data.url.present ? data.url.value : this.url,
      fileCode: data.fileCode.present ? data.fileCode.value : this.fileCode,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('resourceId: $resourceId, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('url: $url, ')
          ..write('fileCode: $fileCode, ')
          ..write('projectId: $projectId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, titre, description, fileName,
      mimeType, url, fileCode, projectId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.resourceId == this.resourceId &&
          other.titre == this.titre &&
          other.description == this.description &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.url == this.url &&
          other.fileCode == this.fileCode &&
          other.projectId == this.projectId);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> resourceId;
  final Value<String> titre;
  final Value<String?> description;
  final Value<String?> fileName;
  final Value<String?> mimeType;
  final Value<String?> url;
  final Value<String?> fileCode;
  final Value<String> projectId;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.resourceId = const Value.absent(),
    this.titre = const Value.absent(),
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.url = const Value.absent(),
    this.fileCode = const Value.absent(),
    this.projectId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String resourceId,
    required String titre,
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.url = const Value.absent(),
    this.fileCode = const Value.absent(),
    required String projectId,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        titre = Value(titre),
        projectId = Value(projectId);
  static Insertable<Document> custom({
    Expression<String>? resourceId,
    Expression<String>? titre,
    Expression<String>? description,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<String>? url,
    Expression<String>? fileCode,
    Expression<String>? projectId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (titre != null) 'titre': titre,
      if (description != null) 'description': description,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (url != null) 'url': url,
      if (fileCode != null) 'file_code': fileCode,
      if (projectId != null) 'project_id': projectId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? titre,
      Value<String?>? description,
      Value<String?>? fileName,
      Value<String?>? mimeType,
      Value<String?>? url,
      Value<String?>? fileCode,
      Value<String>? projectId,
      Value<int>? rowid}) {
    return DocumentsCompanion(
      resourceId: resourceId ?? this.resourceId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      url: url ?? this.url,
      fileCode: fileCode ?? this.fileCode,
      projectId: projectId ?? this.projectId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (titre.present) {
      map['titre'] = Variable<String>(titre.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileCode.present) {
      map['file_code'] = Variable<String>(fileCode.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('url: $url, ')
          ..write('fileCode: $fileCode, ')
          ..write('projectId: $projectId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTmpTable extends DocumentsTmp
    with TableInfo<$DocumentsTmpTable, DocumentTmpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTmpTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentTypeMeta =
      const VerificationMeta('parentType');
  @override
  late final GeneratedColumn<String> parentType = GeneratedColumn<String>(
      'parent_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titreMeta = const VerificationMeta('titre');
  @override
  late final GeneratedColumn<String> titre = GeneratedColumn<String>(
      'titre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileCodeMeta =
      const VerificationMeta('fileCode');
  @override
  late final GeneratedColumn<String> fileCode = GeneratedColumn<String>(
      'file_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _natureConceptIdMeta =
      const VerificationMeta('natureConceptId');
  @override
  late final GeneratedColumn<int> natureConceptId = GeneratedColumn<int>(
      'nature_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scaleConceptIdMeta =
      const VerificationMeta('scaleConceptId');
  @override
  late final GeneratedColumn<int> scaleConceptId = GeneratedColumn<int>(
      'scale_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _formatConceptIdMeta =
      const VerificationMeta('formatConceptId');
  @override
  late final GeneratedColumn<int> formatConceptId = GeneratedColumn<int>(
      'format_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fileContentMeta =
      const VerificationMeta('fileContent');
  @override
  late final GeneratedColumn<Uint8List> fileContent =
      GeneratedColumn<Uint8List>('file_content', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _uploadErrorMeta =
      const VerificationMeta('uploadError');
  @override
  late final GeneratedColumn<String> uploadError = GeneratedColumn<String>(
      'upload_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        resourceId,
        parentType,
        parentId,
        kind,
        status,
        titre,
        description,
        fileName,
        mimeType,
        fileCode,
        url,
        natureConceptId,
        scaleConceptId,
        formatConceptId,
        fileContent,
        fileSize,
        uploadError,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents_tmp';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentTmpRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    }
    if (data.containsKey('parent_type')) {
      context.handle(
          _parentTypeMeta,
          parentType.isAcceptableOrUnknown(
              data['parent_type']!, _parentTypeMeta));
    } else if (isInserting) {
      context.missing(_parentTypeMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    } else if (isInserting) {
      context.missing(_parentIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('titre')) {
      context.handle(
          _titreMeta, titre.isAcceptableOrUnknown(data['titre']!, _titreMeta));
    } else if (isInserting) {
      context.missing(_titreMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('file_code')) {
      context.handle(_fileCodeMeta,
          fileCode.isAcceptableOrUnknown(data['file_code']!, _fileCodeMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('nature_concept_id')) {
      context.handle(
          _natureConceptIdMeta,
          natureConceptId.isAcceptableOrUnknown(
              data['nature_concept_id']!, _natureConceptIdMeta));
    }
    if (data.containsKey('scale_concept_id')) {
      context.handle(
          _scaleConceptIdMeta,
          scaleConceptId.isAcceptableOrUnknown(
              data['scale_concept_id']!, _scaleConceptIdMeta));
    }
    if (data.containsKey('format_concept_id')) {
      context.handle(
          _formatConceptIdMeta,
          formatConceptId.isAcceptableOrUnknown(
              data['format_concept_id']!, _formatConceptIdMeta));
    }
    if (data.containsKey('file_content')) {
      context.handle(
          _fileContentMeta,
          fileContent.isAcceptableOrUnknown(
              data['file_content']!, _fileContentMeta));
    } else if (isInserting) {
      context.missing(_fileContentMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('upload_error')) {
      context.handle(
          _uploadErrorMeta,
          uploadError.isAcceptableOrUnknown(
              data['upload_error']!, _uploadErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  DocumentTmpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentTmpRow(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id']),
      parentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_type'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      titre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titre'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type']),
      fileCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_code']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      natureConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}nature_concept_id']),
      scaleConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scale_concept_id']),
      formatConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}format_concept_id']),
      fileContent: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}file_content'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      uploadError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DocumentsTmpTable createAlias(String alias) {
    return $DocumentsTmpTable(attachedDatabase, alias);
  }
}

class DocumentTmpRow extends DataClass implements Insertable<DocumentTmpRow> {
  /// Identifiant local (UUID).
  final String localId;

  /// Identifiant API une fois synchronisé (ou pour le cache pré-téléchargé).
  final String? resourceId;

  /// `project` ou `recording_unit`.
  final String parentType;
  final String parentId;

  /// `prefetch` (téléchargé pour consultation) ou `pending_upload` (créé hors ligne).
  final String kind;

  /// `pending`, `uploading`, `synced`, `failed`.
  final String status;
  final String titre;
  final String? description;
  final String? fileName;
  final String? mimeType;
  final String? fileCode;
  final String? url;
  final int? natureConceptId;
  final int? scaleConceptId;
  final int? formatConceptId;

  /// Contenu binaire du fichier.
  final Uint8List fileContent;
  final int fileSize;
  final String? uploadError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DocumentTmpRow(
      {required this.localId,
      this.resourceId,
      required this.parentType,
      required this.parentId,
      required this.kind,
      required this.status,
      required this.titre,
      this.description,
      this.fileName,
      this.mimeType,
      this.fileCode,
      this.url,
      this.natureConceptId,
      this.scaleConceptId,
      this.formatConceptId,
      required this.fileContent,
      required this.fileSize,
      this.uploadError,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    map['parent_type'] = Variable<String>(parentType);
    map['parent_id'] = Variable<String>(parentId);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    map['titre'] = Variable<String>(titre);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || fileCode != null) {
      map['file_code'] = Variable<String>(fileCode);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || natureConceptId != null) {
      map['nature_concept_id'] = Variable<int>(natureConceptId);
    }
    if (!nullToAbsent || scaleConceptId != null) {
      map['scale_concept_id'] = Variable<int>(scaleConceptId);
    }
    if (!nullToAbsent || formatConceptId != null) {
      map['format_concept_id'] = Variable<int>(formatConceptId);
    }
    map['file_content'] = Variable<Uint8List>(fileContent);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || uploadError != null) {
      map['upload_error'] = Variable<String>(uploadError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsTmpCompanion toCompanion(bool nullToAbsent) {
    return DocumentsTmpCompanion(
      localId: Value(localId),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
      parentType: Value(parentType),
      parentId: Value(parentId),
      kind: Value(kind),
      status: Value(status),
      titre: Value(titre),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      fileCode: fileCode == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCode),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      natureConceptId: natureConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(natureConceptId),
      scaleConceptId: scaleConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(scaleConceptId),
      formatConceptId: formatConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(formatConceptId),
      fileContent: Value(fileContent),
      fileSize: Value(fileSize),
      uploadError: uploadError == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentTmpRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentTmpRow(
      localId: serializer.fromJson<String>(json['localId']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
      parentType: serializer.fromJson<String>(json['parentType']),
      parentId: serializer.fromJson<String>(json['parentId']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      titre: serializer.fromJson<String>(json['titre']),
      description: serializer.fromJson<String?>(json['description']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      fileCode: serializer.fromJson<String?>(json['fileCode']),
      url: serializer.fromJson<String?>(json['url']),
      natureConceptId: serializer.fromJson<int?>(json['natureConceptId']),
      scaleConceptId: serializer.fromJson<int?>(json['scaleConceptId']),
      formatConceptId: serializer.fromJson<int?>(json['formatConceptId']),
      fileContent: serializer.fromJson<Uint8List>(json['fileContent']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      uploadError: serializer.fromJson<String?>(json['uploadError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'resourceId': serializer.toJson<String?>(resourceId),
      'parentType': serializer.toJson<String>(parentType),
      'parentId': serializer.toJson<String>(parentId),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'titre': serializer.toJson<String>(titre),
      'description': serializer.toJson<String?>(description),
      'fileName': serializer.toJson<String?>(fileName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'fileCode': serializer.toJson<String?>(fileCode),
      'url': serializer.toJson<String?>(url),
      'natureConceptId': serializer.toJson<int?>(natureConceptId),
      'scaleConceptId': serializer.toJson<int?>(scaleConceptId),
      'formatConceptId': serializer.toJson<int?>(formatConceptId),
      'fileContent': serializer.toJson<Uint8List>(fileContent),
      'fileSize': serializer.toJson<int>(fileSize),
      'uploadError': serializer.toJson<String?>(uploadError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentTmpRow copyWith(
          {String? localId,
          Value<String?> resourceId = const Value.absent(),
          String? parentType,
          String? parentId,
          String? kind,
          String? status,
          String? titre,
          Value<String?> description = const Value.absent(),
          Value<String?> fileName = const Value.absent(),
          Value<String?> mimeType = const Value.absent(),
          Value<String?> fileCode = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<int?> natureConceptId = const Value.absent(),
          Value<int?> scaleConceptId = const Value.absent(),
          Value<int?> formatConceptId = const Value.absent(),
          Uint8List? fileContent,
          int? fileSize,
          Value<String?> uploadError = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DocumentTmpRow(
        localId: localId ?? this.localId,
        resourceId: resourceId.present ? resourceId.value : this.resourceId,
        parentType: parentType ?? this.parentType,
        parentId: parentId ?? this.parentId,
        kind: kind ?? this.kind,
        status: status ?? this.status,
        titre: titre ?? this.titre,
        description: description.present ? description.value : this.description,
        fileName: fileName.present ? fileName.value : this.fileName,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        fileCode: fileCode.present ? fileCode.value : this.fileCode,
        url: url.present ? url.value : this.url,
        natureConceptId: natureConceptId.present
            ? natureConceptId.value
            : this.natureConceptId,
        scaleConceptId:
            scaleConceptId.present ? scaleConceptId.value : this.scaleConceptId,
        formatConceptId: formatConceptId.present
            ? formatConceptId.value
            : this.formatConceptId,
        fileContent: fileContent ?? this.fileContent,
        fileSize: fileSize ?? this.fileSize,
        uploadError: uploadError.present ? uploadError.value : this.uploadError,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DocumentTmpRow copyWithCompanion(DocumentsTmpCompanion data) {
    return DocumentTmpRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      parentType:
          data.parentType.present ? data.parentType.value : this.parentType,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      titre: data.titre.present ? data.titre.value : this.titre,
      description:
          data.description.present ? data.description.value : this.description,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileCode: data.fileCode.present ? data.fileCode.value : this.fileCode,
      url: data.url.present ? data.url.value : this.url,
      natureConceptId: data.natureConceptId.present
          ? data.natureConceptId.value
          : this.natureConceptId,
      scaleConceptId: data.scaleConceptId.present
          ? data.scaleConceptId.value
          : this.scaleConceptId,
      formatConceptId: data.formatConceptId.present
          ? data.formatConceptId.value
          : this.formatConceptId,
      fileContent:
          data.fileContent.present ? data.fileContent.value : this.fileContent,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      uploadError:
          data.uploadError.present ? data.uploadError.value : this.uploadError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTmpRow(')
          ..write('localId: $localId, ')
          ..write('resourceId: $resourceId, ')
          ..write('parentType: $parentType, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileCode: $fileCode, ')
          ..write('url: $url, ')
          ..write('natureConceptId: $natureConceptId, ')
          ..write('scaleConceptId: $scaleConceptId, ')
          ..write('formatConceptId: $formatConceptId, ')
          ..write('fileContent: $fileContent, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadError: $uploadError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      resourceId,
      parentType,
      parentId,
      kind,
      status,
      titre,
      description,
      fileName,
      mimeType,
      fileCode,
      url,
      natureConceptId,
      scaleConceptId,
      formatConceptId,
      $driftBlobEquality.hash(fileContent),
      fileSize,
      uploadError,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentTmpRow &&
          other.localId == this.localId &&
          other.resourceId == this.resourceId &&
          other.parentType == this.parentType &&
          other.parentId == this.parentId &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.titre == this.titre &&
          other.description == this.description &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.fileCode == this.fileCode &&
          other.url == this.url &&
          other.natureConceptId == this.natureConceptId &&
          other.scaleConceptId == this.scaleConceptId &&
          other.formatConceptId == this.formatConceptId &&
          $driftBlobEquality.equals(other.fileContent, this.fileContent) &&
          other.fileSize == this.fileSize &&
          other.uploadError == this.uploadError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsTmpCompanion extends UpdateCompanion<DocumentTmpRow> {
  final Value<String> localId;
  final Value<String?> resourceId;
  final Value<String> parentType;
  final Value<String> parentId;
  final Value<String> kind;
  final Value<String> status;
  final Value<String> titre;
  final Value<String?> description;
  final Value<String?> fileName;
  final Value<String?> mimeType;
  final Value<String?> fileCode;
  final Value<String?> url;
  final Value<int?> natureConceptId;
  final Value<int?> scaleConceptId;
  final Value<int?> formatConceptId;
  final Value<Uint8List> fileContent;
  final Value<int> fileSize;
  final Value<String?> uploadError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentsTmpCompanion({
    this.localId = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.parentType = const Value.absent(),
    this.parentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.titre = const Value.absent(),
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileCode = const Value.absent(),
    this.url = const Value.absent(),
    this.natureConceptId = const Value.absent(),
    this.scaleConceptId = const Value.absent(),
    this.formatConceptId = const Value.absent(),
    this.fileContent = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.uploadError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsTmpCompanion.insert({
    required String localId,
    this.resourceId = const Value.absent(),
    required String parentType,
    required String parentId,
    required String kind,
    required String status,
    required String titre,
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileCode = const Value.absent(),
    this.url = const Value.absent(),
    this.natureConceptId = const Value.absent(),
    this.scaleConceptId = const Value.absent(),
    this.formatConceptId = const Value.absent(),
    required Uint8List fileContent,
    this.fileSize = const Value.absent(),
    this.uploadError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        parentType = Value(parentType),
        parentId = Value(parentId),
        kind = Value(kind),
        status = Value(status),
        titre = Value(titre),
        fileContent = Value(fileContent),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DocumentTmpRow> custom({
    Expression<String>? localId,
    Expression<String>? resourceId,
    Expression<String>? parentType,
    Expression<String>? parentId,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<String>? titre,
    Expression<String>? description,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<String>? fileCode,
    Expression<String>? url,
    Expression<int>? natureConceptId,
    Expression<int>? scaleConceptId,
    Expression<int>? formatConceptId,
    Expression<Uint8List>? fileContent,
    Expression<int>? fileSize,
    Expression<String>? uploadError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (resourceId != null) 'resource_id': resourceId,
      if (parentType != null) 'parent_type': parentType,
      if (parentId != null) 'parent_id': parentId,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (titre != null) 'titre': titre,
      if (description != null) 'description': description,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileCode != null) 'file_code': fileCode,
      if (url != null) 'url': url,
      if (natureConceptId != null) 'nature_concept_id': natureConceptId,
      if (scaleConceptId != null) 'scale_concept_id': scaleConceptId,
      if (formatConceptId != null) 'format_concept_id': formatConceptId,
      if (fileContent != null) 'file_content': fileContent,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadError != null) 'upload_error': uploadError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsTmpCompanion copyWith(
      {Value<String>? localId,
      Value<String?>? resourceId,
      Value<String>? parentType,
      Value<String>? parentId,
      Value<String>? kind,
      Value<String>? status,
      Value<String>? titre,
      Value<String?>? description,
      Value<String?>? fileName,
      Value<String?>? mimeType,
      Value<String?>? fileCode,
      Value<String?>? url,
      Value<int?>? natureConceptId,
      Value<int?>? scaleConceptId,
      Value<int?>? formatConceptId,
      Value<Uint8List>? fileContent,
      Value<int>? fileSize,
      Value<String?>? uploadError,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DocumentsTmpCompanion(
      localId: localId ?? this.localId,
      resourceId: resourceId ?? this.resourceId,
      parentType: parentType ?? this.parentType,
      parentId: parentId ?? this.parentId,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileCode: fileCode ?? this.fileCode,
      url: url ?? this.url,
      natureConceptId: natureConceptId ?? this.natureConceptId,
      scaleConceptId: scaleConceptId ?? this.scaleConceptId,
      formatConceptId: formatConceptId ?? this.formatConceptId,
      fileContent: fileContent ?? this.fileContent,
      fileSize: fileSize ?? this.fileSize,
      uploadError: uploadError ?? this.uploadError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (parentType.present) {
      map['parent_type'] = Variable<String>(parentType.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (titre.present) {
      map['titre'] = Variable<String>(titre.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileCode.present) {
      map['file_code'] = Variable<String>(fileCode.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (natureConceptId.present) {
      map['nature_concept_id'] = Variable<int>(natureConceptId.value);
    }
    if (scaleConceptId.present) {
      map['scale_concept_id'] = Variable<int>(scaleConceptId.value);
    }
    if (formatConceptId.present) {
      map['format_concept_id'] = Variable<int>(formatConceptId.value);
    }
    if (fileContent.present) {
      map['file_content'] = Variable<Uint8List>(fileContent.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (uploadError.present) {
      map['upload_error'] = Variable<String>(uploadError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsTmpCompanion(')
          ..write('localId: $localId, ')
          ..write('resourceId: $resourceId, ')
          ..write('parentType: $parentType, ')
          ..write('parentId: $parentId, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileCode: $fileCode, ')
          ..write('url: $url, ')
          ..write('natureConceptId: $natureConceptId, ')
          ..write('scaleConceptId: $scaleConceptId, ')
          ..write('formatConceptId: $formatConceptId, ')
          ..write('fileContent: $fileContent, ')
          ..write('fileSize: $fileSize, ')
          ..write('uploadError: $uploadError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsUniteEnregistrementTable extends DocumentsUniteEnregistrement
    with
        TableInfo<$DocumentsUniteEnregistrementTable,
            DocumentUniteEnregistrement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsUniteEnregistrementTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titreMeta = const VerificationMeta('titre');
  @override
  late final GeneratedColumn<String> titre = GeneratedColumn<String>(
      'titre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileCodeMeta =
      const VerificationMeta('fileCode');
  @override
  late final GeneratedColumn<String> fileCode = GeneratedColumn<String>(
      'file_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _uniteEnregistrementIdMeta =
      const VerificationMeta('uniteEnregistrementId');
  @override
  late final GeneratedColumn<String> uniteEnregistrementId =
      GeneratedColumn<String>('unite_enregistrement_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        resourceId,
        titre,
        description,
        fileName,
        mimeType,
        url,
        fileCode,
        uniteEnregistrementId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents_unite_enregistrement';
  @override
  VerificationContext validateIntegrity(
      Insertable<DocumentUniteEnregistrement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('titre')) {
      context.handle(
          _titreMeta, titre.isAcceptableOrUnknown(data['titre']!, _titreMeta));
    } else if (isInserting) {
      context.missing(_titreMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('file_code')) {
      context.handle(_fileCodeMeta,
          fileCode.isAcceptableOrUnknown(data['file_code']!, _fileCodeMeta));
    }
    if (data.containsKey('unite_enregistrement_id')) {
      context.handle(
          _uniteEnregistrementIdMeta,
          uniteEnregistrementId.isAcceptableOrUnknown(
              data['unite_enregistrement_id']!, _uniteEnregistrementIdMeta));
    } else if (isInserting) {
      context.missing(_uniteEnregistrementIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  DocumentUniteEnregistrement map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentUniteEnregistrement(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      titre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titre'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      fileCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_code']),
      uniteEnregistrementId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unite_enregistrement_id'])!,
    );
  }

  @override
  $DocumentsUniteEnregistrementTable createAlias(String alias) {
    return $DocumentsUniteEnregistrementTable(attachedDatabase, alias);
  }
}

class DocumentUniteEnregistrement extends DataClass
    implements Insertable<DocumentUniteEnregistrement> {
  final String resourceId;
  final String titre;
  final String? description;
  final String? fileName;
  final String? mimeType;
  final String? url;
  final String? fileCode;
  final String uniteEnregistrementId;
  const DocumentUniteEnregistrement(
      {required this.resourceId,
      required this.titre,
      this.description,
      this.fileName,
      this.mimeType,
      this.url,
      this.fileCode,
      required this.uniteEnregistrementId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['titre'] = Variable<String>(titre);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || fileCode != null) {
      map['file_code'] = Variable<String>(fileCode);
    }
    map['unite_enregistrement_id'] = Variable<String>(uniteEnregistrementId);
    return map;
  }

  DocumentsUniteEnregistrementCompanion toCompanion(bool nullToAbsent) {
    return DocumentsUniteEnregistrementCompanion(
      resourceId: Value(resourceId),
      titre: Value(titre),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      fileCode: fileCode == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCode),
      uniteEnregistrementId: Value(uniteEnregistrementId),
    );
  }

  factory DocumentUniteEnregistrement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentUniteEnregistrement(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      titre: serializer.fromJson<String>(json['titre']),
      description: serializer.fromJson<String?>(json['description']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      url: serializer.fromJson<String?>(json['url']),
      fileCode: serializer.fromJson<String?>(json['fileCode']),
      uniteEnregistrementId:
          serializer.fromJson<String>(json['uniteEnregistrementId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'titre': serializer.toJson<String>(titre),
      'description': serializer.toJson<String?>(description),
      'fileName': serializer.toJson<String?>(fileName),
      'mimeType': serializer.toJson<String?>(mimeType),
      'url': serializer.toJson<String?>(url),
      'fileCode': serializer.toJson<String?>(fileCode),
      'uniteEnregistrementId': serializer.toJson<String>(uniteEnregistrementId),
    };
  }

  DocumentUniteEnregistrement copyWith(
          {String? resourceId,
          String? titre,
          Value<String?> description = const Value.absent(),
          Value<String?> fileName = const Value.absent(),
          Value<String?> mimeType = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> fileCode = const Value.absent(),
          String? uniteEnregistrementId}) =>
      DocumentUniteEnregistrement(
        resourceId: resourceId ?? this.resourceId,
        titre: titre ?? this.titre,
        description: description.present ? description.value : this.description,
        fileName: fileName.present ? fileName.value : this.fileName,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        url: url.present ? url.value : this.url,
        fileCode: fileCode.present ? fileCode.value : this.fileCode,
        uniteEnregistrementId:
            uniteEnregistrementId ?? this.uniteEnregistrementId,
      );
  DocumentUniteEnregistrement copyWithCompanion(
      DocumentsUniteEnregistrementCompanion data) {
    return DocumentUniteEnregistrement(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      titre: data.titre.present ? data.titre.value : this.titre,
      description:
          data.description.present ? data.description.value : this.description,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      url: data.url.present ? data.url.value : this.url,
      fileCode: data.fileCode.present ? data.fileCode.value : this.fileCode,
      uniteEnregistrementId: data.uniteEnregistrementId.present
          ? data.uniteEnregistrementId.value
          : this.uniteEnregistrementId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentUniteEnregistrement(')
          ..write('resourceId: $resourceId, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('url: $url, ')
          ..write('fileCode: $fileCode, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, titre, description, fileName,
      mimeType, url, fileCode, uniteEnregistrementId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentUniteEnregistrement &&
          other.resourceId == this.resourceId &&
          other.titre == this.titre &&
          other.description == this.description &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.url == this.url &&
          other.fileCode == this.fileCode &&
          other.uniteEnregistrementId == this.uniteEnregistrementId);
}

class DocumentsUniteEnregistrementCompanion
    extends UpdateCompanion<DocumentUniteEnregistrement> {
  final Value<String> resourceId;
  final Value<String> titre;
  final Value<String?> description;
  final Value<String?> fileName;
  final Value<String?> mimeType;
  final Value<String?> url;
  final Value<String?> fileCode;
  final Value<String> uniteEnregistrementId;
  final Value<int> rowid;
  const DocumentsUniteEnregistrementCompanion({
    this.resourceId = const Value.absent(),
    this.titre = const Value.absent(),
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.url = const Value.absent(),
    this.fileCode = const Value.absent(),
    this.uniteEnregistrementId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsUniteEnregistrementCompanion.insert({
    required String resourceId,
    required String titre,
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.url = const Value.absent(),
    this.fileCode = const Value.absent(),
    required String uniteEnregistrementId,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        titre = Value(titre),
        uniteEnregistrementId = Value(uniteEnregistrementId);
  static Insertable<DocumentUniteEnregistrement> custom({
    Expression<String>? resourceId,
    Expression<String>? titre,
    Expression<String>? description,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<String>? url,
    Expression<String>? fileCode,
    Expression<String>? uniteEnregistrementId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (titre != null) 'titre': titre,
      if (description != null) 'description': description,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (url != null) 'url': url,
      if (fileCode != null) 'file_code': fileCode,
      if (uniteEnregistrementId != null)
        'unite_enregistrement_id': uniteEnregistrementId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsUniteEnregistrementCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? titre,
      Value<String?>? description,
      Value<String?>? fileName,
      Value<String?>? mimeType,
      Value<String?>? url,
      Value<String?>? fileCode,
      Value<String>? uniteEnregistrementId,
      Value<int>? rowid}) {
    return DocumentsUniteEnregistrementCompanion(
      resourceId: resourceId ?? this.resourceId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      url: url ?? this.url,
      fileCode: fileCode ?? this.fileCode,
      uniteEnregistrementId:
          uniteEnregistrementId ?? this.uniteEnregistrementId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (titre.present) {
      map['titre'] = Variable<String>(titre.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileCode.present) {
      map['file_code'] = Variable<String>(fileCode.value);
    }
    if (uniteEnregistrementId.present) {
      map['unite_enregistrement_id'] =
          Variable<String>(uniteEnregistrementId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsUniteEnregistrementCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('titre: $titre, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('url: $url, ')
          ..write('fileCode: $fileCode, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitesEnregistrementTable extends UnitesEnregistrement
    with TableInfo<$UnitesEnregistrementTable, UniteEnregistrement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitesEnregistrementTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayCodeMeta =
      const VerificationMeta('displayCode');
  @override
  late final GeneratedColumn<String> displayCode = GeneratedColumn<String>(
      'display_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _identifierMeta =
      const VerificationMeta('identifier');
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
      'identifier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeLabelMeta =
      const VerificationMeta('typeLabel');
  @override
  late final GeneratedColumn<String> typeLabel = GeneratedColumn<String>(
      'type_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _placeLabelMeta =
      const VerificationMeta('placeLabel');
  @override
  late final GeneratedColumn<String> placeLabel = GeneratedColumn<String>(
      'place_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingDateMeta =
      const VerificationMeta('openingDate');
  @override
  late final GeneratedColumn<DateTime> openingDate = GeneratedColumn<DateTime>(
      'opening_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _closingDateMeta =
      const VerificationMeta('closingDate');
  @override
  late final GeneratedColumn<DateTime> closingDate = GeneratedColumn<DateTime>(
      'closing_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _matrixColorMeta =
      const VerificationMeta('matrixColor');
  @override
  late final GeneratedColumn<String> matrixColor = GeneratedColumn<String>(
      'matrix_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specimenCountMeta =
      const VerificationMeta('specimenCount');
  @override
  late final GeneratedColumn<int> specimenCount = GeneratedColumn<int>(
      'specimen_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stratigraphicCountMeta =
      const VerificationMeta('stratigraphicCount');
  @override
  late final GeneratedColumn<int> stratigraphicCount = GeneratedColumn<int>(
      'stratigraphic_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _typeConceptIdMeta =
      const VerificationMeta('typeConceptId');
  @override
  late final GeneratedColumn<int> typeConceptId = GeneratedColumn<int>(
      'type_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentIdsJsonMeta =
      const VerificationMeta('parentIdsJson');
  @override
  late final GeneratedColumn<String> parentIdsJson = GeneratedColumn<String>(
      'parent_ids_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        resourceId,
        projectId,
        displayCode,
        identifier,
        typeLabel,
        placeLabel,
        openingDate,
        closingDate,
        matrixColor,
        specimenCount,
        stratigraphicCount,
        typeConceptId,
        parentIdsJson,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unites_enregistrement';
  @override
  VerificationContext validateIntegrity(
      Insertable<UniteEnregistrement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('display_code')) {
      context.handle(
          _displayCodeMeta,
          displayCode.isAcceptableOrUnknown(
              data['display_code']!, _displayCodeMeta));
    } else if (isInserting) {
      context.missing(_displayCodeMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
          _identifierMeta,
          identifier.isAcceptableOrUnknown(
              data['identifier']!, _identifierMeta));
    }
    if (data.containsKey('type_label')) {
      context.handle(_typeLabelMeta,
          typeLabel.isAcceptableOrUnknown(data['type_label']!, _typeLabelMeta));
    }
    if (data.containsKey('place_label')) {
      context.handle(
          _placeLabelMeta,
          placeLabel.isAcceptableOrUnknown(
              data['place_label']!, _placeLabelMeta));
    }
    if (data.containsKey('opening_date')) {
      context.handle(
          _openingDateMeta,
          openingDate.isAcceptableOrUnknown(
              data['opening_date']!, _openingDateMeta));
    }
    if (data.containsKey('closing_date')) {
      context.handle(
          _closingDateMeta,
          closingDate.isAcceptableOrUnknown(
              data['closing_date']!, _closingDateMeta));
    }
    if (data.containsKey('matrix_color')) {
      context.handle(
          _matrixColorMeta,
          matrixColor.isAcceptableOrUnknown(
              data['matrix_color']!, _matrixColorMeta));
    }
    if (data.containsKey('specimen_count')) {
      context.handle(
          _specimenCountMeta,
          specimenCount.isAcceptableOrUnknown(
              data['specimen_count']!, _specimenCountMeta));
    }
    if (data.containsKey('stratigraphic_count')) {
      context.handle(
          _stratigraphicCountMeta,
          stratigraphicCount.isAcceptableOrUnknown(
              data['stratigraphic_count']!, _stratigraphicCountMeta));
    }
    if (data.containsKey('type_concept_id')) {
      context.handle(
          _typeConceptIdMeta,
          typeConceptId.isAcceptableOrUnknown(
              data['type_concept_id']!, _typeConceptIdMeta));
    }
    if (data.containsKey('parent_ids_json')) {
      context.handle(
          _parentIdsJsonMeta,
          parentIdsJson.isAcceptableOrUnknown(
              data['parent_ids_json']!, _parentIdsJsonMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  UniteEnregistrement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UniteEnregistrement(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      displayCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_code'])!,
      identifier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}identifier']),
      typeLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type_label']),
      placeLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_label']),
      openingDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opening_date']),
      closingDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closing_date']),
      matrixColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matrix_color']),
      specimenCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}specimen_count']),
      stratigraphicCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}stratigraphic_count']),
      typeConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type_concept_id']),
      parentIdsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_ids_json']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $UnitesEnregistrementTable createAlias(String alias) {
    return $UnitesEnregistrementTable(attachedDatabase, alias);
  }
}

class UniteEnregistrement extends DataClass
    implements Insertable<UniteEnregistrement> {
  final String resourceId;
  final String projectId;
  final String displayCode;
  final String? identifier;
  final String? typeLabel;
  final String? placeLabel;
  final DateTime? openingDate;
  final DateTime? closingDate;
  final String? matrixColor;
  final int? specimenCount;
  final int? stratigraphicCount;
  final int? typeConceptId;

  /// JSON (`["id1","id2"]`) des parents pour l’arborescence hors ligne.
  final String? parentIdsJson;
  final DateTime syncedAt;
  const UniteEnregistrement(
      {required this.resourceId,
      required this.projectId,
      required this.displayCode,
      this.identifier,
      this.typeLabel,
      this.placeLabel,
      this.openingDate,
      this.closingDate,
      this.matrixColor,
      this.specimenCount,
      this.stratigraphicCount,
      this.typeConceptId,
      this.parentIdsJson,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['project_id'] = Variable<String>(projectId);
    map['display_code'] = Variable<String>(displayCode);
    if (!nullToAbsent || identifier != null) {
      map['identifier'] = Variable<String>(identifier);
    }
    if (!nullToAbsent || typeLabel != null) {
      map['type_label'] = Variable<String>(typeLabel);
    }
    if (!nullToAbsent || placeLabel != null) {
      map['place_label'] = Variable<String>(placeLabel);
    }
    if (!nullToAbsent || openingDate != null) {
      map['opening_date'] = Variable<DateTime>(openingDate);
    }
    if (!nullToAbsent || closingDate != null) {
      map['closing_date'] = Variable<DateTime>(closingDate);
    }
    if (!nullToAbsent || matrixColor != null) {
      map['matrix_color'] = Variable<String>(matrixColor);
    }
    if (!nullToAbsent || specimenCount != null) {
      map['specimen_count'] = Variable<int>(specimenCount);
    }
    if (!nullToAbsent || stratigraphicCount != null) {
      map['stratigraphic_count'] = Variable<int>(stratigraphicCount);
    }
    if (!nullToAbsent || typeConceptId != null) {
      map['type_concept_id'] = Variable<int>(typeConceptId);
    }
    if (!nullToAbsent || parentIdsJson != null) {
      map['parent_ids_json'] = Variable<String>(parentIdsJson);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  UnitesEnregistrementCompanion toCompanion(bool nullToAbsent) {
    return UnitesEnregistrementCompanion(
      resourceId: Value(resourceId),
      projectId: Value(projectId),
      displayCode: Value(displayCode),
      identifier: identifier == null && nullToAbsent
          ? const Value.absent()
          : Value(identifier),
      typeLabel: typeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(typeLabel),
      placeLabel: placeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(placeLabel),
      openingDate: openingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(openingDate),
      closingDate: closingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(closingDate),
      matrixColor: matrixColor == null && nullToAbsent
          ? const Value.absent()
          : Value(matrixColor),
      specimenCount: specimenCount == null && nullToAbsent
          ? const Value.absent()
          : Value(specimenCount),
      stratigraphicCount: stratigraphicCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stratigraphicCount),
      typeConceptId: typeConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeConceptId),
      parentIdsJson: parentIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(parentIdsJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory UniteEnregistrement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UniteEnregistrement(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      displayCode: serializer.fromJson<String>(json['displayCode']),
      identifier: serializer.fromJson<String?>(json['identifier']),
      typeLabel: serializer.fromJson<String?>(json['typeLabel']),
      placeLabel: serializer.fromJson<String?>(json['placeLabel']),
      openingDate: serializer.fromJson<DateTime?>(json['openingDate']),
      closingDate: serializer.fromJson<DateTime?>(json['closingDate']),
      matrixColor: serializer.fromJson<String?>(json['matrixColor']),
      specimenCount: serializer.fromJson<int?>(json['specimenCount']),
      stratigraphicCount: serializer.fromJson<int?>(json['stratigraphicCount']),
      typeConceptId: serializer.fromJson<int?>(json['typeConceptId']),
      parentIdsJson: serializer.fromJson<String?>(json['parentIdsJson']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'projectId': serializer.toJson<String>(projectId),
      'displayCode': serializer.toJson<String>(displayCode),
      'identifier': serializer.toJson<String?>(identifier),
      'typeLabel': serializer.toJson<String?>(typeLabel),
      'placeLabel': serializer.toJson<String?>(placeLabel),
      'openingDate': serializer.toJson<DateTime?>(openingDate),
      'closingDate': serializer.toJson<DateTime?>(closingDate),
      'matrixColor': serializer.toJson<String?>(matrixColor),
      'specimenCount': serializer.toJson<int?>(specimenCount),
      'stratigraphicCount': serializer.toJson<int?>(stratigraphicCount),
      'typeConceptId': serializer.toJson<int?>(typeConceptId),
      'parentIdsJson': serializer.toJson<String?>(parentIdsJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  UniteEnregistrement copyWith(
          {String? resourceId,
          String? projectId,
          String? displayCode,
          Value<String?> identifier = const Value.absent(),
          Value<String?> typeLabel = const Value.absent(),
          Value<String?> placeLabel = const Value.absent(),
          Value<DateTime?> openingDate = const Value.absent(),
          Value<DateTime?> closingDate = const Value.absent(),
          Value<String?> matrixColor = const Value.absent(),
          Value<int?> specimenCount = const Value.absent(),
          Value<int?> stratigraphicCount = const Value.absent(),
          Value<int?> typeConceptId = const Value.absent(),
          Value<String?> parentIdsJson = const Value.absent(),
          DateTime? syncedAt}) =>
      UniteEnregistrement(
        resourceId: resourceId ?? this.resourceId,
        projectId: projectId ?? this.projectId,
        displayCode: displayCode ?? this.displayCode,
        identifier: identifier.present ? identifier.value : this.identifier,
        typeLabel: typeLabel.present ? typeLabel.value : this.typeLabel,
        placeLabel: placeLabel.present ? placeLabel.value : this.placeLabel,
        openingDate: openingDate.present ? openingDate.value : this.openingDate,
        closingDate: closingDate.present ? closingDate.value : this.closingDate,
        matrixColor: matrixColor.present ? matrixColor.value : this.matrixColor,
        specimenCount:
            specimenCount.present ? specimenCount.value : this.specimenCount,
        stratigraphicCount: stratigraphicCount.present
            ? stratigraphicCount.value
            : this.stratigraphicCount,
        typeConceptId:
            typeConceptId.present ? typeConceptId.value : this.typeConceptId,
        parentIdsJson:
            parentIdsJson.present ? parentIdsJson.value : this.parentIdsJson,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  UniteEnregistrement copyWithCompanion(UnitesEnregistrementCompanion data) {
    return UniteEnregistrement(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      displayCode:
          data.displayCode.present ? data.displayCode.value : this.displayCode,
      identifier:
          data.identifier.present ? data.identifier.value : this.identifier,
      typeLabel: data.typeLabel.present ? data.typeLabel.value : this.typeLabel,
      placeLabel:
          data.placeLabel.present ? data.placeLabel.value : this.placeLabel,
      openingDate:
          data.openingDate.present ? data.openingDate.value : this.openingDate,
      closingDate:
          data.closingDate.present ? data.closingDate.value : this.closingDate,
      matrixColor:
          data.matrixColor.present ? data.matrixColor.value : this.matrixColor,
      specimenCount: data.specimenCount.present
          ? data.specimenCount.value
          : this.specimenCount,
      stratigraphicCount: data.stratigraphicCount.present
          ? data.stratigraphicCount.value
          : this.stratigraphicCount,
      typeConceptId: data.typeConceptId.present
          ? data.typeConceptId.value
          : this.typeConceptId,
      parentIdsJson: data.parentIdsJson.present
          ? data.parentIdsJson.value
          : this.parentIdsJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UniteEnregistrement(')
          ..write('resourceId: $resourceId, ')
          ..write('projectId: $projectId, ')
          ..write('displayCode: $displayCode, ')
          ..write('identifier: $identifier, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('placeLabel: $placeLabel, ')
          ..write('openingDate: $openingDate, ')
          ..write('closingDate: $closingDate, ')
          ..write('matrixColor: $matrixColor, ')
          ..write('specimenCount: $specimenCount, ')
          ..write('stratigraphicCount: $stratigraphicCount, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('parentIdsJson: $parentIdsJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      resourceId,
      projectId,
      displayCode,
      identifier,
      typeLabel,
      placeLabel,
      openingDate,
      closingDate,
      matrixColor,
      specimenCount,
      stratigraphicCount,
      typeConceptId,
      parentIdsJson,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UniteEnregistrement &&
          other.resourceId == this.resourceId &&
          other.projectId == this.projectId &&
          other.displayCode == this.displayCode &&
          other.identifier == this.identifier &&
          other.typeLabel == this.typeLabel &&
          other.placeLabel == this.placeLabel &&
          other.openingDate == this.openingDate &&
          other.closingDate == this.closingDate &&
          other.matrixColor == this.matrixColor &&
          other.specimenCount == this.specimenCount &&
          other.stratigraphicCount == this.stratigraphicCount &&
          other.typeConceptId == this.typeConceptId &&
          other.parentIdsJson == this.parentIdsJson &&
          other.syncedAt == this.syncedAt);
}

class UnitesEnregistrementCompanion
    extends UpdateCompanion<UniteEnregistrement> {
  final Value<String> resourceId;
  final Value<String> projectId;
  final Value<String> displayCode;
  final Value<String?> identifier;
  final Value<String?> typeLabel;
  final Value<String?> placeLabel;
  final Value<DateTime?> openingDate;
  final Value<DateTime?> closingDate;
  final Value<String?> matrixColor;
  final Value<int?> specimenCount;
  final Value<int?> stratigraphicCount;
  final Value<int?> typeConceptId;
  final Value<String?> parentIdsJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const UnitesEnregistrementCompanion({
    this.resourceId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.displayCode = const Value.absent(),
    this.identifier = const Value.absent(),
    this.typeLabel = const Value.absent(),
    this.placeLabel = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.closingDate = const Value.absent(),
    this.matrixColor = const Value.absent(),
    this.specimenCount = const Value.absent(),
    this.stratigraphicCount = const Value.absent(),
    this.typeConceptId = const Value.absent(),
    this.parentIdsJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitesEnregistrementCompanion.insert({
    required String resourceId,
    required String projectId,
    required String displayCode,
    this.identifier = const Value.absent(),
    this.typeLabel = const Value.absent(),
    this.placeLabel = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.closingDate = const Value.absent(),
    this.matrixColor = const Value.absent(),
    this.specimenCount = const Value.absent(),
    this.stratigraphicCount = const Value.absent(),
    this.typeConceptId = const Value.absent(),
    this.parentIdsJson = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        projectId = Value(projectId),
        displayCode = Value(displayCode),
        syncedAt = Value(syncedAt);
  static Insertable<UniteEnregistrement> custom({
    Expression<String>? resourceId,
    Expression<String>? projectId,
    Expression<String>? displayCode,
    Expression<String>? identifier,
    Expression<String>? typeLabel,
    Expression<String>? placeLabel,
    Expression<DateTime>? openingDate,
    Expression<DateTime>? closingDate,
    Expression<String>? matrixColor,
    Expression<int>? specimenCount,
    Expression<int>? stratigraphicCount,
    Expression<int>? typeConceptId,
    Expression<String>? parentIdsJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (projectId != null) 'project_id': projectId,
      if (displayCode != null) 'display_code': displayCode,
      if (identifier != null) 'identifier': identifier,
      if (typeLabel != null) 'type_label': typeLabel,
      if (placeLabel != null) 'place_label': placeLabel,
      if (openingDate != null) 'opening_date': openingDate,
      if (closingDate != null) 'closing_date': closingDate,
      if (matrixColor != null) 'matrix_color': matrixColor,
      if (specimenCount != null) 'specimen_count': specimenCount,
      if (stratigraphicCount != null) 'stratigraphic_count': stratigraphicCount,
      if (typeConceptId != null) 'type_concept_id': typeConceptId,
      if (parentIdsJson != null) 'parent_ids_json': parentIdsJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitesEnregistrementCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? projectId,
      Value<String>? displayCode,
      Value<String?>? identifier,
      Value<String?>? typeLabel,
      Value<String?>? placeLabel,
      Value<DateTime?>? openingDate,
      Value<DateTime?>? closingDate,
      Value<String?>? matrixColor,
      Value<int?>? specimenCount,
      Value<int?>? stratigraphicCount,
      Value<int?>? typeConceptId,
      Value<String?>? parentIdsJson,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return UnitesEnregistrementCompanion(
      resourceId: resourceId ?? this.resourceId,
      projectId: projectId ?? this.projectId,
      displayCode: displayCode ?? this.displayCode,
      identifier: identifier ?? this.identifier,
      typeLabel: typeLabel ?? this.typeLabel,
      placeLabel: placeLabel ?? this.placeLabel,
      openingDate: openingDate ?? this.openingDate,
      closingDate: closingDate ?? this.closingDate,
      matrixColor: matrixColor ?? this.matrixColor,
      specimenCount: specimenCount ?? this.specimenCount,
      stratigraphicCount: stratigraphicCount ?? this.stratigraphicCount,
      typeConceptId: typeConceptId ?? this.typeConceptId,
      parentIdsJson: parentIdsJson ?? this.parentIdsJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (displayCode.present) {
      map['display_code'] = Variable<String>(displayCode.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (typeLabel.present) {
      map['type_label'] = Variable<String>(typeLabel.value);
    }
    if (placeLabel.present) {
      map['place_label'] = Variable<String>(placeLabel.value);
    }
    if (openingDate.present) {
      map['opening_date'] = Variable<DateTime>(openingDate.value);
    }
    if (closingDate.present) {
      map['closing_date'] = Variable<DateTime>(closingDate.value);
    }
    if (matrixColor.present) {
      map['matrix_color'] = Variable<String>(matrixColor.value);
    }
    if (specimenCount.present) {
      map['specimen_count'] = Variable<int>(specimenCount.value);
    }
    if (stratigraphicCount.present) {
      map['stratigraphic_count'] = Variable<int>(stratigraphicCount.value);
    }
    if (typeConceptId.present) {
      map['type_concept_id'] = Variable<int>(typeConceptId.value);
    }
    if (parentIdsJson.present) {
      map['parent_ids_json'] = Variable<String>(parentIdsJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitesEnregistrementCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('projectId: $projectId, ')
          ..write('displayCode: $displayCode, ')
          ..write('identifier: $identifier, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('placeLabel: $placeLabel, ')
          ..write('openingDate: $openingDate, ')
          ..write('closingDate: $closingDate, ')
          ..write('matrixColor: $matrixColor, ')
          ..write('specimenCount: $specimenCount, ')
          ..write('stratigraphicCount: $stratigraphicCount, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('parentIdsJson: $parentIdsJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitesEnregistrementDetailTable extends UnitesEnregistrementDetail
    with
        TableInfo<$UnitesEnregistrementDetailTable,
            UniteEnregistrementDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitesEnregistrementDetailTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _detailJsonMeta =
      const VerificationMeta('detailJson');
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
      'detail_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeConceptIdMeta =
      const VerificationMeta('typeConceptId');
  @override
  late final GeneratedColumn<int> typeConceptId = GeneratedColumn<int>(
      'type_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [resourceId, detailJson, typeConceptId, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unites_enregistrement_detail';
  @override
  VerificationContext validateIntegrity(
      Insertable<UniteEnregistrementDetailRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('detail_json')) {
      context.handle(
          _detailJsonMeta,
          detailJson.isAcceptableOrUnknown(
              data['detail_json']!, _detailJsonMeta));
    } else if (isInserting) {
      context.missing(_detailJsonMeta);
    }
    if (data.containsKey('type_concept_id')) {
      context.handle(
          _typeConceptIdMeta,
          typeConceptId.isAcceptableOrUnknown(
              data['type_concept_id']!, _typeConceptIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  UniteEnregistrementDetailRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UniteEnregistrementDetailRow(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      detailJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}detail_json'])!,
      typeConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type_concept_id']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $UnitesEnregistrementDetailTable createAlias(String alias) {
    return $UnitesEnregistrementDetailTable(attachedDatabase, alias);
  }
}

class UniteEnregistrementDetailRow extends DataClass
    implements Insertable<UniteEnregistrementDetailRow> {
  final String resourceId;
  final String detailJson;
  final int? typeConceptId;
  final DateTime syncedAt;
  const UniteEnregistrementDetailRow(
      {required this.resourceId,
      required this.detailJson,
      this.typeConceptId,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['detail_json'] = Variable<String>(detailJson);
    if (!nullToAbsent || typeConceptId != null) {
      map['type_concept_id'] = Variable<int>(typeConceptId);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  UnitesEnregistrementDetailCompanion toCompanion(bool nullToAbsent) {
    return UnitesEnregistrementDetailCompanion(
      resourceId: Value(resourceId),
      detailJson: Value(detailJson),
      typeConceptId: typeConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeConceptId),
      syncedAt: Value(syncedAt),
    );
  }

  factory UniteEnregistrementDetailRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UniteEnregistrementDetailRow(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      detailJson: serializer.fromJson<String>(json['detailJson']),
      typeConceptId: serializer.fromJson<int?>(json['typeConceptId']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'detailJson': serializer.toJson<String>(detailJson),
      'typeConceptId': serializer.toJson<int?>(typeConceptId),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  UniteEnregistrementDetailRow copyWith(
          {String? resourceId,
          String? detailJson,
          Value<int?> typeConceptId = const Value.absent(),
          DateTime? syncedAt}) =>
      UniteEnregistrementDetailRow(
        resourceId: resourceId ?? this.resourceId,
        detailJson: detailJson ?? this.detailJson,
        typeConceptId:
            typeConceptId.present ? typeConceptId.value : this.typeConceptId,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  UniteEnregistrementDetailRow copyWithCompanion(
      UnitesEnregistrementDetailCompanion data) {
    return UniteEnregistrementDetailRow(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      detailJson:
          data.detailJson.present ? data.detailJson.value : this.detailJson,
      typeConceptId: data.typeConceptId.present
          ? data.typeConceptId.value
          : this.typeConceptId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UniteEnregistrementDetailRow(')
          ..write('resourceId: $resourceId, ')
          ..write('detailJson: $detailJson, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourceId, detailJson, typeConceptId, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UniteEnregistrementDetailRow &&
          other.resourceId == this.resourceId &&
          other.detailJson == this.detailJson &&
          other.typeConceptId == this.typeConceptId &&
          other.syncedAt == this.syncedAt);
}

class UnitesEnregistrementDetailCompanion
    extends UpdateCompanion<UniteEnregistrementDetailRow> {
  final Value<String> resourceId;
  final Value<String> detailJson;
  final Value<int?> typeConceptId;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const UnitesEnregistrementDetailCompanion({
    this.resourceId = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.typeConceptId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitesEnregistrementDetailCompanion.insert({
    required String resourceId,
    required String detailJson,
    this.typeConceptId = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        detailJson = Value(detailJson),
        syncedAt = Value(syncedAt);
  static Insertable<UniteEnregistrementDetailRow> custom({
    Expression<String>? resourceId,
    Expression<String>? detailJson,
    Expression<int>? typeConceptId,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (detailJson != null) 'detail_json': detailJson,
      if (typeConceptId != null) 'type_concept_id': typeConceptId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitesEnregistrementDetailCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? detailJson,
      Value<int?>? typeConceptId,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return UnitesEnregistrementDetailCompanion(
      resourceId: resourceId ?? this.resourceId,
      detailJson: detailJson ?? this.detailJson,
      typeConceptId: typeConceptId ?? this.typeConceptId,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (typeConceptId.present) {
      map['type_concept_id'] = Variable<int>(typeConceptId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitesEnregistrementDetailCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('detailJson: $detailJson, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncActionsTable extends SyncActions
    with TableInfo<$SyncActionsTable, SyncActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionIdMeta =
      const VerificationMeta('actionId');
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
      'action_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localEntityIdMeta =
      const VerificationMeta('localEntityId');
  @override
  late final GeneratedColumn<String> localEntityId = GeneratedColumn<String>(
      'local_entity_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverEntityIdMeta =
      const VerificationMeta('serverEntityId');
  @override
  late final GeneratedColumn<String> serverEntityId = GeneratedColumn<String>(
      'server_entity_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentTypeMeta =
      const VerificationMeta('parentType');
  @override
  late final GeneratedColumn<String> parentType = GeneratedColumn<String>(
      'parent_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentLocalIdMeta =
      const VerificationMeta('parentLocalId');
  @override
  late final GeneratedColumn<String> parentLocalId = GeneratedColumn<String>(
      'parent_local_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentServerIdMeta =
      const VerificationMeta('parentServerId');
  @override
  late final GeneratedColumn<String> parentServerId = GeneratedColumn<String>(
      'parent_server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _blobRefMeta =
      const VerificationMeta('blobRef');
  @override
  late final GeneratedColumn<String> blobRef = GeneratedColumn<String>(
      'blob_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _baseServerRevisionMeta =
      const VerificationMeta('baseServerRevision');
  @override
  late final GeneratedColumn<int> baseServerRevision = GeneratedColumn<int>(
      'base_server_revision', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        actionId,
        sequence,
        operation,
        entityType,
        localEntityId,
        serverEntityId,
        parentType,
        parentLocalId,
        parentServerId,
        payloadJson,
        blobRef,
        baseServerRevision,
        status,
        errorMessage,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_actions';
  @override
  VerificationContext validateIntegrity(Insertable<SyncActionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_id')) {
      context.handle(_actionIdMeta,
          actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta));
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('local_entity_id')) {
      context.handle(
          _localEntityIdMeta,
          localEntityId.isAcceptableOrUnknown(
              data['local_entity_id']!, _localEntityIdMeta));
    }
    if (data.containsKey('server_entity_id')) {
      context.handle(
          _serverEntityIdMeta,
          serverEntityId.isAcceptableOrUnknown(
              data['server_entity_id']!, _serverEntityIdMeta));
    }
    if (data.containsKey('parent_type')) {
      context.handle(
          _parentTypeMeta,
          parentType.isAcceptableOrUnknown(
              data['parent_type']!, _parentTypeMeta));
    }
    if (data.containsKey('parent_local_id')) {
      context.handle(
          _parentLocalIdMeta,
          parentLocalId.isAcceptableOrUnknown(
              data['parent_local_id']!, _parentLocalIdMeta));
    }
    if (data.containsKey('parent_server_id')) {
      context.handle(
          _parentServerIdMeta,
          parentServerId.isAcceptableOrUnknown(
              data['parent_server_id']!, _parentServerIdMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('blob_ref')) {
      context.handle(_blobRefMeta,
          blobRef.isAcceptableOrUnknown(data['blob_ref']!, _blobRefMeta));
    }
    if (data.containsKey('base_server_revision')) {
      context.handle(
          _baseServerRevisionMeta,
          baseServerRevision.isAcceptableOrUnknown(
              data['base_server_revision']!, _baseServerRevisionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionId};
  @override
  SyncActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncActionRow(
      actionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_id'])!,
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      localEntityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_entity_id']),
      serverEntityId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}server_entity_id']),
      parentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_type']),
      parentLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_local_id']),
      parentServerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parent_server_id']),
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      blobRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blob_ref']),
      baseServerRevision: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}base_server_revision']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncActionsTable createAlias(String alias) {
    return $SyncActionsTable(attachedDatabase, alias);
  }
}

class SyncActionRow extends DataClass implements Insertable<SyncActionRow> {
  final String actionId;
  final int sequence;
  final String operation;
  final String entityType;
  final String? localEntityId;
  final String? serverEntityId;
  final String? parentType;
  final String? parentLocalId;
  final String? parentServerId;
  final String payloadJson;
  final String? blobRef;
  final int? baseServerRevision;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncActionRow(
      {required this.actionId,
      required this.sequence,
      required this.operation,
      required this.entityType,
      this.localEntityId,
      this.serverEntityId,
      this.parentType,
      this.parentLocalId,
      this.parentServerId,
      required this.payloadJson,
      this.blobRef,
      this.baseServerRevision,
      required this.status,
      this.errorMessage,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_id'] = Variable<String>(actionId);
    map['sequence'] = Variable<int>(sequence);
    map['operation'] = Variable<String>(operation);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || localEntityId != null) {
      map['local_entity_id'] = Variable<String>(localEntityId);
    }
    if (!nullToAbsent || serverEntityId != null) {
      map['server_entity_id'] = Variable<String>(serverEntityId);
    }
    if (!nullToAbsent || parentType != null) {
      map['parent_type'] = Variable<String>(parentType);
    }
    if (!nullToAbsent || parentLocalId != null) {
      map['parent_local_id'] = Variable<String>(parentLocalId);
    }
    if (!nullToAbsent || parentServerId != null) {
      map['parent_server_id'] = Variable<String>(parentServerId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || blobRef != null) {
      map['blob_ref'] = Variable<String>(blobRef);
    }
    if (!nullToAbsent || baseServerRevision != null) {
      map['base_server_revision'] = Variable<int>(baseServerRevision);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncActionsCompanion toCompanion(bool nullToAbsent) {
    return SyncActionsCompanion(
      actionId: Value(actionId),
      sequence: Value(sequence),
      operation: Value(operation),
      entityType: Value(entityType),
      localEntityId: localEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(localEntityId),
      serverEntityId: serverEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverEntityId),
      parentType: parentType == null && nullToAbsent
          ? const Value.absent()
          : Value(parentType),
      parentLocalId: parentLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentLocalId),
      parentServerId: parentServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentServerId),
      payloadJson: Value(payloadJson),
      blobRef: blobRef == null && nullToAbsent
          ? const Value.absent()
          : Value(blobRef),
      baseServerRevision: baseServerRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerRevision),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncActionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncActionRow(
      actionId: serializer.fromJson<String>(json['actionId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      operation: serializer.fromJson<String>(json['operation']),
      entityType: serializer.fromJson<String>(json['entityType']),
      localEntityId: serializer.fromJson<String?>(json['localEntityId']),
      serverEntityId: serializer.fromJson<String?>(json['serverEntityId']),
      parentType: serializer.fromJson<String?>(json['parentType']),
      parentLocalId: serializer.fromJson<String?>(json['parentLocalId']),
      parentServerId: serializer.fromJson<String?>(json['parentServerId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      blobRef: serializer.fromJson<String?>(json['blobRef']),
      baseServerRevision: serializer.fromJson<int?>(json['baseServerRevision']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionId': serializer.toJson<String>(actionId),
      'sequence': serializer.toJson<int>(sequence),
      'operation': serializer.toJson<String>(operation),
      'entityType': serializer.toJson<String>(entityType),
      'localEntityId': serializer.toJson<String?>(localEntityId),
      'serverEntityId': serializer.toJson<String?>(serverEntityId),
      'parentType': serializer.toJson<String?>(parentType),
      'parentLocalId': serializer.toJson<String?>(parentLocalId),
      'parentServerId': serializer.toJson<String?>(parentServerId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'blobRef': serializer.toJson<String?>(blobRef),
      'baseServerRevision': serializer.toJson<int?>(baseServerRevision),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncActionRow copyWith(
          {String? actionId,
          int? sequence,
          String? operation,
          String? entityType,
          Value<String?> localEntityId = const Value.absent(),
          Value<String?> serverEntityId = const Value.absent(),
          Value<String?> parentType = const Value.absent(),
          Value<String?> parentLocalId = const Value.absent(),
          Value<String?> parentServerId = const Value.absent(),
          String? payloadJson,
          Value<String?> blobRef = const Value.absent(),
          Value<int?> baseServerRevision = const Value.absent(),
          String? status,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncActionRow(
        actionId: actionId ?? this.actionId,
        sequence: sequence ?? this.sequence,
        operation: operation ?? this.operation,
        entityType: entityType ?? this.entityType,
        localEntityId:
            localEntityId.present ? localEntityId.value : this.localEntityId,
        serverEntityId:
            serverEntityId.present ? serverEntityId.value : this.serverEntityId,
        parentType: parentType.present ? parentType.value : this.parentType,
        parentLocalId:
            parentLocalId.present ? parentLocalId.value : this.parentLocalId,
        parentServerId:
            parentServerId.present ? parentServerId.value : this.parentServerId,
        payloadJson: payloadJson ?? this.payloadJson,
        blobRef: blobRef.present ? blobRef.value : this.blobRef,
        baseServerRevision: baseServerRevision.present
            ? baseServerRevision.value
            : this.baseServerRevision,
        status: status ?? this.status,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncActionRow copyWithCompanion(SyncActionsCompanion data) {
    return SyncActionRow(
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      localEntityId: data.localEntityId.present
          ? data.localEntityId.value
          : this.localEntityId,
      serverEntityId: data.serverEntityId.present
          ? data.serverEntityId.value
          : this.serverEntityId,
      parentType:
          data.parentType.present ? data.parentType.value : this.parentType,
      parentLocalId: data.parentLocalId.present
          ? data.parentLocalId.value
          : this.parentLocalId,
      parentServerId: data.parentServerId.present
          ? data.parentServerId.value
          : this.parentServerId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      blobRef: data.blobRef.present ? data.blobRef.value : this.blobRef,
      baseServerRevision: data.baseServerRevision.present
          ? data.baseServerRevision.value
          : this.baseServerRevision,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncActionRow(')
          ..write('actionId: $actionId, ')
          ..write('sequence: $sequence, ')
          ..write('operation: $operation, ')
          ..write('entityType: $entityType, ')
          ..write('localEntityId: $localEntityId, ')
          ..write('serverEntityId: $serverEntityId, ')
          ..write('parentType: $parentType, ')
          ..write('parentLocalId: $parentLocalId, ')
          ..write('parentServerId: $parentServerId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('blobRef: $blobRef, ')
          ..write('baseServerRevision: $baseServerRevision, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      actionId,
      sequence,
      operation,
      entityType,
      localEntityId,
      serverEntityId,
      parentType,
      parentLocalId,
      parentServerId,
      payloadJson,
      blobRef,
      baseServerRevision,
      status,
      errorMessage,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncActionRow &&
          other.actionId == this.actionId &&
          other.sequence == this.sequence &&
          other.operation == this.operation &&
          other.entityType == this.entityType &&
          other.localEntityId == this.localEntityId &&
          other.serverEntityId == this.serverEntityId &&
          other.parentType == this.parentType &&
          other.parentLocalId == this.parentLocalId &&
          other.parentServerId == this.parentServerId &&
          other.payloadJson == this.payloadJson &&
          other.blobRef == this.blobRef &&
          other.baseServerRevision == this.baseServerRevision &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncActionsCompanion extends UpdateCompanion<SyncActionRow> {
  final Value<String> actionId;
  final Value<int> sequence;
  final Value<String> operation;
  final Value<String> entityType;
  final Value<String?> localEntityId;
  final Value<String?> serverEntityId;
  final Value<String?> parentType;
  final Value<String?> parentLocalId;
  final Value<String?> parentServerId;
  final Value<String> payloadJson;
  final Value<String?> blobRef;
  final Value<int?> baseServerRevision;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncActionsCompanion({
    this.actionId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityType = const Value.absent(),
    this.localEntityId = const Value.absent(),
    this.serverEntityId = const Value.absent(),
    this.parentType = const Value.absent(),
    this.parentLocalId = const Value.absent(),
    this.parentServerId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.blobRef = const Value.absent(),
    this.baseServerRevision = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncActionsCompanion.insert({
    required String actionId,
    required int sequence,
    required String operation,
    required String entityType,
    this.localEntityId = const Value.absent(),
    this.serverEntityId = const Value.absent(),
    this.parentType = const Value.absent(),
    this.parentLocalId = const Value.absent(),
    this.parentServerId = const Value.absent(),
    required String payloadJson,
    this.blobRef = const Value.absent(),
    this.baseServerRevision = const Value.absent(),
    required String status,
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : actionId = Value(actionId),
        sequence = Value(sequence),
        operation = Value(operation),
        entityType = Value(entityType),
        payloadJson = Value(payloadJson),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncActionRow> custom({
    Expression<String>? actionId,
    Expression<int>? sequence,
    Expression<String>? operation,
    Expression<String>? entityType,
    Expression<String>? localEntityId,
    Expression<String>? serverEntityId,
    Expression<String>? parentType,
    Expression<String>? parentLocalId,
    Expression<String>? parentServerId,
    Expression<String>? payloadJson,
    Expression<String>? blobRef,
    Expression<int>? baseServerRevision,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionId != null) 'action_id': actionId,
      if (sequence != null) 'sequence': sequence,
      if (operation != null) 'operation': operation,
      if (entityType != null) 'entity_type': entityType,
      if (localEntityId != null) 'local_entity_id': localEntityId,
      if (serverEntityId != null) 'server_entity_id': serverEntityId,
      if (parentType != null) 'parent_type': parentType,
      if (parentLocalId != null) 'parent_local_id': parentLocalId,
      if (parentServerId != null) 'parent_server_id': parentServerId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (blobRef != null) 'blob_ref': blobRef,
      if (baseServerRevision != null)
        'base_server_revision': baseServerRevision,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncActionsCompanion copyWith(
      {Value<String>? actionId,
      Value<int>? sequence,
      Value<String>? operation,
      Value<String>? entityType,
      Value<String?>? localEntityId,
      Value<String?>? serverEntityId,
      Value<String?>? parentType,
      Value<String?>? parentLocalId,
      Value<String?>? parentServerId,
      Value<String>? payloadJson,
      Value<String?>? blobRef,
      Value<int?>? baseServerRevision,
      Value<String>? status,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncActionsCompanion(
      actionId: actionId ?? this.actionId,
      sequence: sequence ?? this.sequence,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      localEntityId: localEntityId ?? this.localEntityId,
      serverEntityId: serverEntityId ?? this.serverEntityId,
      parentType: parentType ?? this.parentType,
      parentLocalId: parentLocalId ?? this.parentLocalId,
      parentServerId: parentServerId ?? this.parentServerId,
      payloadJson: payloadJson ?? this.payloadJson,
      blobRef: blobRef ?? this.blobRef,
      baseServerRevision: baseServerRevision ?? this.baseServerRevision,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (localEntityId.present) {
      map['local_entity_id'] = Variable<String>(localEntityId.value);
    }
    if (serverEntityId.present) {
      map['server_entity_id'] = Variable<String>(serverEntityId.value);
    }
    if (parentType.present) {
      map['parent_type'] = Variable<String>(parentType.value);
    }
    if (parentLocalId.present) {
      map['parent_local_id'] = Variable<String>(parentLocalId.value);
    }
    if (parentServerId.present) {
      map['parent_server_id'] = Variable<String>(parentServerId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (blobRef.present) {
      map['blob_ref'] = Variable<String>(blobRef.value);
    }
    if (baseServerRevision.present) {
      map['base_server_revision'] = Variable<int>(baseServerRevision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncActionsCompanion(')
          ..write('actionId: $actionId, ')
          ..write('sequence: $sequence, ')
          ..write('operation: $operation, ')
          ..write('entityType: $entityType, ')
          ..write('localEntityId: $localEntityId, ')
          ..write('serverEntityId: $serverEntityId, ')
          ..write('parentType: $parentType, ')
          ..write('parentLocalId: $parentLocalId, ')
          ..write('parentServerId: $parentServerId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('blobRef: $blobRef, ')
          ..write('baseServerRevision: $baseServerRevision, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitySyncSnapshotsTable extends EntitySyncSnapshots
    with TableInfo<$EntitySyncSnapshotsTable, EntitySyncSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitySyncSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseServerRevisionMeta =
      const VerificationMeta('baseServerRevision');
  @override
  late final GeneratedColumn<int> baseServerRevision = GeneratedColumn<int>(
      'base_server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _snapshotJsonMeta =
      const VerificationMeta('snapshotJson');
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
      'snapshot_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [entityType, entityId, baseServerRevision, snapshotJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_sync_snapshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<EntitySyncSnapshotRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('base_server_revision')) {
      context.handle(
          _baseServerRevisionMeta,
          baseServerRevision.isAcceptableOrUnknown(
              data['base_server_revision']!, _baseServerRevisionMeta));
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
          _snapshotJsonMeta,
          snapshotJson.isAcceptableOrUnknown(
              data['snapshot_json']!, _snapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  EntitySyncSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitySyncSnapshotRow(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      baseServerRevision: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}base_server_revision'])!,
      snapshotJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}snapshot_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EntitySyncSnapshotsTable createAlias(String alias) {
    return $EntitySyncSnapshotsTable(attachedDatabase, alias);
  }
}

class EntitySyncSnapshotRow extends DataClass
    implements Insertable<EntitySyncSnapshotRow> {
  final String entityType;
  final String entityId;
  final int baseServerRevision;
  final String snapshotJson;
  final DateTime updatedAt;
  const EntitySyncSnapshotRow(
      {required this.entityType,
      required this.entityId,
      required this.baseServerRevision,
      required this.snapshotJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['base_server_revision'] = Variable<int>(baseServerRevision);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntitySyncSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return EntitySyncSnapshotsCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      baseServerRevision: Value(baseServerRevision),
      snapshotJson: Value(snapshotJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory EntitySyncSnapshotRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitySyncSnapshotRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      baseServerRevision: serializer.fromJson<int>(json['baseServerRevision']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'baseServerRevision': serializer.toJson<int>(baseServerRevision),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EntitySyncSnapshotRow copyWith(
          {String? entityType,
          String? entityId,
          int? baseServerRevision,
          String? snapshotJson,
          DateTime? updatedAt}) =>
      EntitySyncSnapshotRow(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        baseServerRevision: baseServerRevision ?? this.baseServerRevision,
        snapshotJson: snapshotJson ?? this.snapshotJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EntitySyncSnapshotRow copyWithCompanion(EntitySyncSnapshotsCompanion data) {
    return EntitySyncSnapshotRow(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      baseServerRevision: data.baseServerRevision.present
          ? data.baseServerRevision.value
          : this.baseServerRevision,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitySyncSnapshotRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('baseServerRevision: $baseServerRevision, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entityType, entityId, baseServerRevision, snapshotJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitySyncSnapshotRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.baseServerRevision == this.baseServerRevision &&
          other.snapshotJson == this.snapshotJson &&
          other.updatedAt == this.updatedAt);
}

class EntitySyncSnapshotsCompanion
    extends UpdateCompanion<EntitySyncSnapshotRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int> baseServerRevision;
  final Value<String> snapshotJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntitySyncSnapshotsCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.baseServerRevision = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitySyncSnapshotsCompanion.insert({
    required String entityType,
    required String entityId,
    this.baseServerRevision = const Value.absent(),
    required String snapshotJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        snapshotJson = Value(snapshotJson),
        updatedAt = Value(updatedAt);
  static Insertable<EntitySyncSnapshotRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? baseServerRevision,
    Expression<String>? snapshotJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (baseServerRevision != null)
        'base_server_revision': baseServerRevision,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitySyncSnapshotsCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? entityId,
      Value<int>? baseServerRevision,
      Value<String>? snapshotJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return EntitySyncSnapshotsCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      baseServerRevision: baseServerRevision ?? this.baseServerRevision,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (baseServerRevision.present) {
      map['base_server_revision'] = Variable<int>(baseServerRevision.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitySyncSnapshotsCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('baseServerRevision: $baseServerRevision, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MobiliersTable extends Mobiliers
    with TableInfo<$MobiliersTable, MobilierCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MobiliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uniteEnregistrementIdMeta =
      const VerificationMeta('uniteEnregistrementId');
  @override
  late final GeneratedColumn<String> uniteEnregistrementId =
      GeneratedColumn<String>('unite_enregistrement_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayCodeMeta =
      const VerificationMeta('displayCode');
  @override
  late final GeneratedColumn<String> displayCode = GeneratedColumn<String>(
      'display_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeLabelMeta =
      const VerificationMeta('typeLabel');
  @override
  late final GeneratedColumn<String> typeLabel = GeneratedColumn<String>(
      'type_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _collectionDateMeta =
      const VerificationMeta('collectionDate');
  @override
  late final GeneratedColumn<DateTime> collectionDate =
      GeneratedColumn<DateTime>('collection_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        resourceId,
        uniteEnregistrementId,
        displayCode,
        typeLabel,
        collectionDate,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mobiliers';
  @override
  VerificationContext validateIntegrity(Insertable<MobilierCache> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('unite_enregistrement_id')) {
      context.handle(
          _uniteEnregistrementIdMeta,
          uniteEnregistrementId.isAcceptableOrUnknown(
              data['unite_enregistrement_id']!, _uniteEnregistrementIdMeta));
    } else if (isInserting) {
      context.missing(_uniteEnregistrementIdMeta);
    }
    if (data.containsKey('display_code')) {
      context.handle(
          _displayCodeMeta,
          displayCode.isAcceptableOrUnknown(
              data['display_code']!, _displayCodeMeta));
    } else if (isInserting) {
      context.missing(_displayCodeMeta);
    }
    if (data.containsKey('type_label')) {
      context.handle(_typeLabelMeta,
          typeLabel.isAcceptableOrUnknown(data['type_label']!, _typeLabelMeta));
    }
    if (data.containsKey('collection_date')) {
      context.handle(
          _collectionDateMeta,
          collectionDate.isAcceptableOrUnknown(
              data['collection_date']!, _collectionDateMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  MobilierCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MobilierCache(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      uniteEnregistrementId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unite_enregistrement_id'])!,
      displayCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_code'])!,
      typeLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type_label']),
      collectionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}collection_date']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $MobiliersTable createAlias(String alias) {
    return $MobiliersTable(attachedDatabase, alias);
  }
}

class MobilierCache extends DataClass implements Insertable<MobilierCache> {
  final String resourceId;
  final String uniteEnregistrementId;
  final String displayCode;
  final String? typeLabel;
  final DateTime? collectionDate;
  final DateTime syncedAt;
  const MobilierCache(
      {required this.resourceId,
      required this.uniteEnregistrementId,
      required this.displayCode,
      this.typeLabel,
      this.collectionDate,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['unite_enregistrement_id'] = Variable<String>(uniteEnregistrementId);
    map['display_code'] = Variable<String>(displayCode);
    if (!nullToAbsent || typeLabel != null) {
      map['type_label'] = Variable<String>(typeLabel);
    }
    if (!nullToAbsent || collectionDate != null) {
      map['collection_date'] = Variable<DateTime>(collectionDate);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MobiliersCompanion toCompanion(bool nullToAbsent) {
    return MobiliersCompanion(
      resourceId: Value(resourceId),
      uniteEnregistrementId: Value(uniteEnregistrementId),
      displayCode: Value(displayCode),
      typeLabel: typeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(typeLabel),
      collectionDate: collectionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionDate),
      syncedAt: Value(syncedAt),
    );
  }

  factory MobilierCache.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MobilierCache(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      uniteEnregistrementId:
          serializer.fromJson<String>(json['uniteEnregistrementId']),
      displayCode: serializer.fromJson<String>(json['displayCode']),
      typeLabel: serializer.fromJson<String?>(json['typeLabel']),
      collectionDate: serializer.fromJson<DateTime?>(json['collectionDate']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'uniteEnregistrementId': serializer.toJson<String>(uniteEnregistrementId),
      'displayCode': serializer.toJson<String>(displayCode),
      'typeLabel': serializer.toJson<String?>(typeLabel),
      'collectionDate': serializer.toJson<DateTime?>(collectionDate),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MobilierCache copyWith(
          {String? resourceId,
          String? uniteEnregistrementId,
          String? displayCode,
          Value<String?> typeLabel = const Value.absent(),
          Value<DateTime?> collectionDate = const Value.absent(),
          DateTime? syncedAt}) =>
      MobilierCache(
        resourceId: resourceId ?? this.resourceId,
        uniteEnregistrementId:
            uniteEnregistrementId ?? this.uniteEnregistrementId,
        displayCode: displayCode ?? this.displayCode,
        typeLabel: typeLabel.present ? typeLabel.value : this.typeLabel,
        collectionDate:
            collectionDate.present ? collectionDate.value : this.collectionDate,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  MobilierCache copyWithCompanion(MobiliersCompanion data) {
    return MobilierCache(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      uniteEnregistrementId: data.uniteEnregistrementId.present
          ? data.uniteEnregistrementId.value
          : this.uniteEnregistrementId,
      displayCode:
          data.displayCode.present ? data.displayCode.value : this.displayCode,
      typeLabel: data.typeLabel.present ? data.typeLabel.value : this.typeLabel,
      collectionDate: data.collectionDate.present
          ? data.collectionDate.value
          : this.collectionDate,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MobilierCache(')
          ..write('resourceId: $resourceId, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId, ')
          ..write('displayCode: $displayCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('collectionDate: $collectionDate, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resourceId, uniteEnregistrementId,
      displayCode, typeLabel, collectionDate, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MobilierCache &&
          other.resourceId == this.resourceId &&
          other.uniteEnregistrementId == this.uniteEnregistrementId &&
          other.displayCode == this.displayCode &&
          other.typeLabel == this.typeLabel &&
          other.collectionDate == this.collectionDate &&
          other.syncedAt == this.syncedAt);
}

class MobiliersCompanion extends UpdateCompanion<MobilierCache> {
  final Value<String> resourceId;
  final Value<String> uniteEnregistrementId;
  final Value<String> displayCode;
  final Value<String?> typeLabel;
  final Value<DateTime?> collectionDate;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MobiliersCompanion({
    this.resourceId = const Value.absent(),
    this.uniteEnregistrementId = const Value.absent(),
    this.displayCode = const Value.absent(),
    this.typeLabel = const Value.absent(),
    this.collectionDate = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MobiliersCompanion.insert({
    required String resourceId,
    required String uniteEnregistrementId,
    required String displayCode,
    this.typeLabel = const Value.absent(),
    this.collectionDate = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        uniteEnregistrementId = Value(uniteEnregistrementId),
        displayCode = Value(displayCode),
        syncedAt = Value(syncedAt);
  static Insertable<MobilierCache> custom({
    Expression<String>? resourceId,
    Expression<String>? uniteEnregistrementId,
    Expression<String>? displayCode,
    Expression<String>? typeLabel,
    Expression<DateTime>? collectionDate,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (uniteEnregistrementId != null)
        'unite_enregistrement_id': uniteEnregistrementId,
      if (displayCode != null) 'display_code': displayCode,
      if (typeLabel != null) 'type_label': typeLabel,
      if (collectionDate != null) 'collection_date': collectionDate,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MobiliersCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? uniteEnregistrementId,
      Value<String>? displayCode,
      Value<String?>? typeLabel,
      Value<DateTime?>? collectionDate,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return MobiliersCompanion(
      resourceId: resourceId ?? this.resourceId,
      uniteEnregistrementId:
          uniteEnregistrementId ?? this.uniteEnregistrementId,
      displayCode: displayCode ?? this.displayCode,
      typeLabel: typeLabel ?? this.typeLabel,
      collectionDate: collectionDate ?? this.collectionDate,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (uniteEnregistrementId.present) {
      map['unite_enregistrement_id'] =
          Variable<String>(uniteEnregistrementId.value);
    }
    if (displayCode.present) {
      map['display_code'] = Variable<String>(displayCode.value);
    }
    if (typeLabel.present) {
      map['type_label'] = Variable<String>(typeLabel.value);
    }
    if (collectionDate.present) {
      map['collection_date'] = Variable<DateTime>(collectionDate.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MobiliersCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId, ')
          ..write('displayCode: $displayCode, ')
          ..write('typeLabel: $typeLabel, ')
          ..write('collectionDate: $collectionDate, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MobiliersDetailTable extends MobiliersDetail
    with TableInfo<$MobiliersDetailTable, MobilierDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MobiliersDetailTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uniteEnregistrementIdMeta =
      const VerificationMeta('uniteEnregistrementId');
  @override
  late final GeneratedColumn<String> uniteEnregistrementId =
      GeneratedColumn<String>('unite_enregistrement_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldsJsonMeta =
      const VerificationMeta('fieldsJson');
  @override
  late final GeneratedColumn<String> fieldsJson = GeneratedColumn<String>(
      'fields_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [resourceId, uniteEnregistrementId, fieldsJson, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mobiliers_detail';
  @override
  VerificationContext validateIntegrity(Insertable<MobilierDetailRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('unite_enregistrement_id')) {
      context.handle(
          _uniteEnregistrementIdMeta,
          uniteEnregistrementId.isAcceptableOrUnknown(
              data['unite_enregistrement_id']!, _uniteEnregistrementIdMeta));
    } else if (isInserting) {
      context.missing(_uniteEnregistrementIdMeta);
    }
    if (data.containsKey('fields_json')) {
      context.handle(
          _fieldsJsonMeta,
          fieldsJson.isAcceptableOrUnknown(
              data['fields_json']!, _fieldsJsonMeta));
    } else if (isInserting) {
      context.missing(_fieldsJsonMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resourceId};
  @override
  MobilierDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MobilierDetailRow(
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      uniteEnregistrementId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unite_enregistrement_id'])!,
      fieldsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fields_json'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $MobiliersDetailTable createAlias(String alias) {
    return $MobiliersDetailTable(attachedDatabase, alias);
  }
}

class MobilierDetailRow extends DataClass
    implements Insertable<MobilierDetailRow> {
  final String resourceId;
  final String uniteEnregistrementId;
  final String fieldsJson;
  final DateTime syncedAt;
  const MobilierDetailRow(
      {required this.resourceId,
      required this.uniteEnregistrementId,
      required this.fieldsJson,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource_id'] = Variable<String>(resourceId);
    map['unite_enregistrement_id'] = Variable<String>(uniteEnregistrementId);
    map['fields_json'] = Variable<String>(fieldsJson);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MobiliersDetailCompanion toCompanion(bool nullToAbsent) {
    return MobiliersDetailCompanion(
      resourceId: Value(resourceId),
      uniteEnregistrementId: Value(uniteEnregistrementId),
      fieldsJson: Value(fieldsJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory MobilierDetailRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MobilierDetailRow(
      resourceId: serializer.fromJson<String>(json['resourceId']),
      uniteEnregistrementId:
          serializer.fromJson<String>(json['uniteEnregistrementId']),
      fieldsJson: serializer.fromJson<String>(json['fieldsJson']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resourceId': serializer.toJson<String>(resourceId),
      'uniteEnregistrementId': serializer.toJson<String>(uniteEnregistrementId),
      'fieldsJson': serializer.toJson<String>(fieldsJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MobilierDetailRow copyWith(
          {String? resourceId,
          String? uniteEnregistrementId,
          String? fieldsJson,
          DateTime? syncedAt}) =>
      MobilierDetailRow(
        resourceId: resourceId ?? this.resourceId,
        uniteEnregistrementId:
            uniteEnregistrementId ?? this.uniteEnregistrementId,
        fieldsJson: fieldsJson ?? this.fieldsJson,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  MobilierDetailRow copyWithCompanion(MobiliersDetailCompanion data) {
    return MobilierDetailRow(
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      uniteEnregistrementId: data.uniteEnregistrementId.present
          ? data.uniteEnregistrementId.value
          : this.uniteEnregistrementId,
      fieldsJson:
          data.fieldsJson.present ? data.fieldsJson.value : this.fieldsJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MobilierDetailRow(')
          ..write('resourceId: $resourceId, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resourceId, uniteEnregistrementId, fieldsJson, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MobilierDetailRow &&
          other.resourceId == this.resourceId &&
          other.uniteEnregistrementId == this.uniteEnregistrementId &&
          other.fieldsJson == this.fieldsJson &&
          other.syncedAt == this.syncedAt);
}

class MobiliersDetailCompanion extends UpdateCompanion<MobilierDetailRow> {
  final Value<String> resourceId;
  final Value<String> uniteEnregistrementId;
  final Value<String> fieldsJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MobiliersDetailCompanion({
    this.resourceId = const Value.absent(),
    this.uniteEnregistrementId = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MobiliersDetailCompanion.insert({
    required String resourceId,
    required String uniteEnregistrementId,
    required String fieldsJson,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : resourceId = Value(resourceId),
        uniteEnregistrementId = Value(uniteEnregistrementId),
        fieldsJson = Value(fieldsJson),
        syncedAt = Value(syncedAt);
  static Insertable<MobilierDetailRow> custom({
    Expression<String>? resourceId,
    Expression<String>? uniteEnregistrementId,
    Expression<String>? fieldsJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resourceId != null) 'resource_id': resourceId,
      if (uniteEnregistrementId != null)
        'unite_enregistrement_id': uniteEnregistrementId,
      if (fieldsJson != null) 'fields_json': fieldsJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MobiliersDetailCompanion copyWith(
      {Value<String>? resourceId,
      Value<String>? uniteEnregistrementId,
      Value<String>? fieldsJson,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return MobiliersDetailCompanion(
      resourceId: resourceId ?? this.resourceId,
      uniteEnregistrementId:
          uniteEnregistrementId ?? this.uniteEnregistrementId,
      fieldsJson: fieldsJson ?? this.fieldsJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (uniteEnregistrementId.present) {
      map['unite_enregistrement_id'] =
          Variable<String>(uniteEnregistrementId.value);
    }
    if (fieldsJson.present) {
      map['fields_json'] = Variable<String>(fieldsJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MobiliersDetailCompanion(')
          ..write('resourceId: $resourceId, ')
          ..write('uniteEnregistrementId: $uniteEnregistrementId, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThesaurusSettingsTable extends ThesaurusSettings
    with TableInfo<$ThesaurusSettingsTable, ThesaurusSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThesaurusSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organisationIdMeta =
      const VerificationMeta('organisationId');
  @override
  late final GeneratedColumn<int> organisationId = GeneratedColumn<int>(
      'organisation_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organisations (id)'));
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thesaurusUrlMeta =
      const VerificationMeta('thesaurusUrl');
  @override
  late final GeneratedColumn<String> thesaurusUrl = GeneratedColumn<String>(
      'thesaurus_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thesaurusLabelMeta =
      const VerificationMeta('thesaurusLabel');
  @override
  late final GeneratedColumn<String> thesaurusLabel = GeneratedColumn<String>(
      'thesaurus_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userConfiguredMeta =
      const VerificationMeta('userConfigured');
  @override
  late final GeneratedColumn<bool> userConfigured = GeneratedColumn<bool>(
      'user_configured', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("user_configured" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _serverSyncedAtMeta =
      const VerificationMeta('serverSyncedAt');
  @override
  late final GeneratedColumn<DateTime> serverSyncedAt =
      GeneratedColumn<DateTime>('server_synced_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        organisationId,
        scope,
        thesaurusUrl,
        thesaurusLabel,
        userConfigured,
        updatedAt,
        serverSyncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thesaurus_settings';
  @override
  VerificationContext validateIntegrity(
      Insertable<ThesaurusSettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organisation_id')) {
      context.handle(
          _organisationIdMeta,
          organisationId.isAcceptableOrUnknown(
              data['organisation_id']!, _organisationIdMeta));
    } else if (isInserting) {
      context.missing(_organisationIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('thesaurus_url')) {
      context.handle(
          _thesaurusUrlMeta,
          thesaurusUrl.isAcceptableOrUnknown(
              data['thesaurus_url']!, _thesaurusUrlMeta));
    } else if (isInserting) {
      context.missing(_thesaurusUrlMeta);
    }
    if (data.containsKey('thesaurus_label')) {
      context.handle(
          _thesaurusLabelMeta,
          thesaurusLabel.isAcceptableOrUnknown(
              data['thesaurus_label']!, _thesaurusLabelMeta));
    }
    if (data.containsKey('user_configured')) {
      context.handle(
          _userConfiguredMeta,
          userConfigured.isAcceptableOrUnknown(
              data['user_configured']!, _userConfiguredMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_synced_at')) {
      context.handle(
          _serverSyncedAtMeta,
          serverSyncedAt.isAcceptableOrUnknown(
              data['server_synced_at']!, _serverSyncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organisationId, scope};
  @override
  ThesaurusSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThesaurusSettingRow(
      organisationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organisation_id'])!,
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      thesaurusUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thesaurus_url'])!,
      thesaurusLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thesaurus_label']),
      userConfigured: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}user_configured'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      serverSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}server_synced_at']),
    );
  }

  @override
  $ThesaurusSettingsTable createAlias(String alias) {
    return $ThesaurusSettingsTable(attachedDatabase, alias);
  }
}

class ThesaurusSettingRow extends DataClass
    implements Insertable<ThesaurusSettingRow> {
  final int organisationId;

  /// `user` (Mon thésaurus).
  final String scope;
  final String thesaurusUrl;

  /// Libellé du thésaurus (ex. SIASU), issu de `data.thesaurus.label`.
  final String? thesaurusLabel;

  /// `true` = config personnelle ; `false` = repli organisation.
  final bool userConfigured;
  final DateTime updatedAt;

  /// Dernière application réussie côté serveur (null = en attente ou hors ligne).
  final DateTime? serverSyncedAt;
  const ThesaurusSettingRow(
      {required this.organisationId,
      required this.scope,
      required this.thesaurusUrl,
      this.thesaurusLabel,
      required this.userConfigured,
      required this.updatedAt,
      this.serverSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organisation_id'] = Variable<int>(organisationId);
    map['scope'] = Variable<String>(scope);
    map['thesaurus_url'] = Variable<String>(thesaurusUrl);
    if (!nullToAbsent || thesaurusLabel != null) {
      map['thesaurus_label'] = Variable<String>(thesaurusLabel);
    }
    map['user_configured'] = Variable<bool>(userConfigured);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverSyncedAt != null) {
      map['server_synced_at'] = Variable<DateTime>(serverSyncedAt);
    }
    return map;
  }

  ThesaurusSettingsCompanion toCompanion(bool nullToAbsent) {
    return ThesaurusSettingsCompanion(
      organisationId: Value(organisationId),
      scope: Value(scope),
      thesaurusUrl: Value(thesaurusUrl),
      thesaurusLabel: thesaurusLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(thesaurusLabel),
      userConfigured: Value(userConfigured),
      updatedAt: Value(updatedAt),
      serverSyncedAt: serverSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSyncedAt),
    );
  }

  factory ThesaurusSettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThesaurusSettingRow(
      organisationId: serializer.fromJson<int>(json['organisationId']),
      scope: serializer.fromJson<String>(json['scope']),
      thesaurusUrl: serializer.fromJson<String>(json['thesaurusUrl']),
      thesaurusLabel: serializer.fromJson<String?>(json['thesaurusLabel']),
      userConfigured: serializer.fromJson<bool>(json['userConfigured']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverSyncedAt: serializer.fromJson<DateTime?>(json['serverSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organisationId': serializer.toJson<int>(organisationId),
      'scope': serializer.toJson<String>(scope),
      'thesaurusUrl': serializer.toJson<String>(thesaurusUrl),
      'thesaurusLabel': serializer.toJson<String?>(thesaurusLabel),
      'userConfigured': serializer.toJson<bool>(userConfigured),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverSyncedAt': serializer.toJson<DateTime?>(serverSyncedAt),
    };
  }

  ThesaurusSettingRow copyWith(
          {int? organisationId,
          String? scope,
          String? thesaurusUrl,
          Value<String?> thesaurusLabel = const Value.absent(),
          bool? userConfigured,
          DateTime? updatedAt,
          Value<DateTime?> serverSyncedAt = const Value.absent()}) =>
      ThesaurusSettingRow(
        organisationId: organisationId ?? this.organisationId,
        scope: scope ?? this.scope,
        thesaurusUrl: thesaurusUrl ?? this.thesaurusUrl,
        thesaurusLabel:
            thesaurusLabel.present ? thesaurusLabel.value : this.thesaurusLabel,
        userConfigured: userConfigured ?? this.userConfigured,
        updatedAt: updatedAt ?? this.updatedAt,
        serverSyncedAt:
            serverSyncedAt.present ? serverSyncedAt.value : this.serverSyncedAt,
      );
  ThesaurusSettingRow copyWithCompanion(ThesaurusSettingsCompanion data) {
    return ThesaurusSettingRow(
      organisationId: data.organisationId.present
          ? data.organisationId.value
          : this.organisationId,
      scope: data.scope.present ? data.scope.value : this.scope,
      thesaurusUrl: data.thesaurusUrl.present
          ? data.thesaurusUrl.value
          : this.thesaurusUrl,
      thesaurusLabel: data.thesaurusLabel.present
          ? data.thesaurusLabel.value
          : this.thesaurusLabel,
      userConfigured: data.userConfigured.present
          ? data.userConfigured.value
          : this.userConfigured,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverSyncedAt: data.serverSyncedAt.present
          ? data.serverSyncedAt.value
          : this.serverSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThesaurusSettingRow(')
          ..write('organisationId: $organisationId, ')
          ..write('scope: $scope, ')
          ..write('thesaurusUrl: $thesaurusUrl, ')
          ..write('thesaurusLabel: $thesaurusLabel, ')
          ..write('userConfigured: $userConfigured, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverSyncedAt: $serverSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organisationId, scope, thesaurusUrl,
      thesaurusLabel, userConfigured, updatedAt, serverSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThesaurusSettingRow &&
          other.organisationId == this.organisationId &&
          other.scope == this.scope &&
          other.thesaurusUrl == this.thesaurusUrl &&
          other.thesaurusLabel == this.thesaurusLabel &&
          other.userConfigured == this.userConfigured &&
          other.updatedAt == this.updatedAt &&
          other.serverSyncedAt == this.serverSyncedAt);
}

class ThesaurusSettingsCompanion extends UpdateCompanion<ThesaurusSettingRow> {
  final Value<int> organisationId;
  final Value<String> scope;
  final Value<String> thesaurusUrl;
  final Value<String?> thesaurusLabel;
  final Value<bool> userConfigured;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> serverSyncedAt;
  final Value<int> rowid;
  const ThesaurusSettingsCompanion({
    this.organisationId = const Value.absent(),
    this.scope = const Value.absent(),
    this.thesaurusUrl = const Value.absent(),
    this.thesaurusLabel = const Value.absent(),
    this.userConfigured = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThesaurusSettingsCompanion.insert({
    required int organisationId,
    required String scope,
    required String thesaurusUrl,
    this.thesaurusLabel = const Value.absent(),
    this.userConfigured = const Value.absent(),
    required DateTime updatedAt,
    this.serverSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : organisationId = Value(organisationId),
        scope = Value(scope),
        thesaurusUrl = Value(thesaurusUrl),
        updatedAt = Value(updatedAt);
  static Insertable<ThesaurusSettingRow> custom({
    Expression<int>? organisationId,
    Expression<String>? scope,
    Expression<String>? thesaurusUrl,
    Expression<String>? thesaurusLabel,
    Expression<bool>? userConfigured,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? serverSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organisationId != null) 'organisation_id': organisationId,
      if (scope != null) 'scope': scope,
      if (thesaurusUrl != null) 'thesaurus_url': thesaurusUrl,
      if (thesaurusLabel != null) 'thesaurus_label': thesaurusLabel,
      if (userConfigured != null) 'user_configured': userConfigured,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverSyncedAt != null) 'server_synced_at': serverSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThesaurusSettingsCompanion copyWith(
      {Value<int>? organisationId,
      Value<String>? scope,
      Value<String>? thesaurusUrl,
      Value<String?>? thesaurusLabel,
      Value<bool>? userConfigured,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? serverSyncedAt,
      Value<int>? rowid}) {
    return ThesaurusSettingsCompanion(
      organisationId: organisationId ?? this.organisationId,
      scope: scope ?? this.scope,
      thesaurusUrl: thesaurusUrl ?? this.thesaurusUrl,
      thesaurusLabel: thesaurusLabel ?? this.thesaurusLabel,
      userConfigured: userConfigured ?? this.userConfigured,
      updatedAt: updatedAt ?? this.updatedAt,
      serverSyncedAt: serverSyncedAt ?? this.serverSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organisationId.present) {
      map['organisation_id'] = Variable<int>(organisationId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (thesaurusUrl.present) {
      map['thesaurus_url'] = Variable<String>(thesaurusUrl.value);
    }
    if (thesaurusLabel.present) {
      map['thesaurus_label'] = Variable<String>(thesaurusLabel.value);
    }
    if (userConfigured.present) {
      map['user_configured'] = Variable<bool>(userConfigured.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverSyncedAt.present) {
      map['server_synced_at'] = Variable<DateTime>(serverSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThesaurusSettingsCompanion(')
          ..write('organisationId: $organisationId, ')
          ..write('scope: $scope, ')
          ..write('thesaurusUrl: $thesaurusUrl, ')
          ..write('thesaurusLabel: $thesaurusLabel, ')
          ..write('userConfigured: $userConfigured, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverSyncedAt: $serverSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LieuxTable extends Lieux with TableInfo<$LieuxTable, LieuCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LieuxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<int> placeId = GeneratedColumn<int>(
      'place_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _organisationIdMeta =
      const VerificationMeta('organisationId');
  @override
  late final GeneratedColumn<int> organisationId = GeneratedColumn<int>(
      'organisation_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organisations (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pendingDeleteMeta =
      const VerificationMeta('pendingDelete');
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
      'pending_delete', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_delete" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _typeConceptIdMeta =
      const VerificationMeta('typeConceptId');
  @override
  late final GeneratedColumn<int> typeConceptId = GeneratedColumn<int>(
      'type_concept_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _addressJsonMeta =
      const VerificationMeta('addressJson');
  @override
  late final GeneratedColumn<String> addressJson = GeneratedColumn<String>(
      'address_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        placeId,
        organisationId,
        name,
        code,
        pendingSync,
        pendingDelete,
        typeConceptId,
        addressJson,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lieux';
  @override
  VerificationContext validateIntegrity(Insertable<LieuCache> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('organisation_id')) {
      context.handle(
          _organisationIdMeta,
          organisationId.isAcceptableOrUnknown(
              data['organisation_id']!, _organisationIdMeta));
    } else if (isInserting) {
      context.missing(_organisationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
          _pendingDeleteMeta,
          pendingDelete.isAcceptableOrUnknown(
              data['pending_delete']!, _pendingDeleteMeta));
    }
    if (data.containsKey('type_concept_id')) {
      context.handle(
          _typeConceptIdMeta,
          typeConceptId.isAcceptableOrUnknown(
              data['type_concept_id']!, _typeConceptIdMeta));
    }
    if (data.containsKey('address_json')) {
      context.handle(
          _addressJsonMeta,
          addressJson.isAcceptableOrUnknown(
              data['address_json']!, _addressJsonMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placeId, organisationId};
  @override
  LieuCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LieuCache(
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}place_id'])!,
      organisationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organisation_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      pendingDelete: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_delete'])!,
      typeConceptId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type_concept_id']),
      addressJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address_json']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $LieuxTable createAlias(String alias) {
    return $LieuxTable(attachedDatabase, alias);
  }
}

class LieuCache extends DataClass implements Insertable<LieuCache> {
  /// Identifiant serveur (> 0) ou identifiant local temporaire (< 0).
  final int placeId;
  final int organisationId;
  final String name;
  final String? code;
  final bool pendingSync;
  final bool pendingDelete;
  final int? typeConceptId;
  final String? addressJson;
  final DateTime syncedAt;
  const LieuCache(
      {required this.placeId,
      required this.organisationId,
      required this.name,
      this.code,
      required this.pendingSync,
      required this.pendingDelete,
      this.typeConceptId,
      this.addressJson,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['place_id'] = Variable<int>(placeId);
    map['organisation_id'] = Variable<int>(organisationId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    if (!nullToAbsent || typeConceptId != null) {
      map['type_concept_id'] = Variable<int>(typeConceptId);
    }
    if (!nullToAbsent || addressJson != null) {
      map['address_json'] = Variable<String>(addressJson);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  LieuxCompanion toCompanion(bool nullToAbsent) {
    return LieuxCompanion(
      placeId: Value(placeId),
      organisationId: Value(organisationId),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      pendingSync: Value(pendingSync),
      pendingDelete: Value(pendingDelete),
      typeConceptId: typeConceptId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeConceptId),
      addressJson: addressJson == null && nullToAbsent
          ? const Value.absent()
          : Value(addressJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory LieuCache.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LieuCache(
      placeId: serializer.fromJson<int>(json['placeId']),
      organisationId: serializer.fromJson<int>(json['organisationId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
      typeConceptId: serializer.fromJson<int?>(json['typeConceptId']),
      addressJson: serializer.fromJson<String?>(json['addressJson']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'placeId': serializer.toJson<int>(placeId),
      'organisationId': serializer.toJson<int>(organisationId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
      'typeConceptId': serializer.toJson<int?>(typeConceptId),
      'addressJson': serializer.toJson<String?>(addressJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  LieuCache copyWith(
          {int? placeId,
          int? organisationId,
          String? name,
          Value<String?> code = const Value.absent(),
          bool? pendingSync,
          bool? pendingDelete,
          Value<int?> typeConceptId = const Value.absent(),
          Value<String?> addressJson = const Value.absent(),
          DateTime? syncedAt}) =>
      LieuCache(
        placeId: placeId ?? this.placeId,
        organisationId: organisationId ?? this.organisationId,
        name: name ?? this.name,
        code: code.present ? code.value : this.code,
        pendingSync: pendingSync ?? this.pendingSync,
        pendingDelete: pendingDelete ?? this.pendingDelete,
        typeConceptId:
            typeConceptId.present ? typeConceptId.value : this.typeConceptId,
        addressJson: addressJson.present ? addressJson.value : this.addressJson,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  LieuCache copyWithCompanion(LieuxCompanion data) {
    return LieuCache(
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      organisationId: data.organisationId.present
          ? data.organisationId.value
          : this.organisationId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
      typeConceptId: data.typeConceptId.present
          ? data.typeConceptId.value
          : this.typeConceptId,
      addressJson:
          data.addressJson.present ? data.addressJson.value : this.addressJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LieuCache(')
          ..write('placeId: $placeId, ')
          ..write('organisationId: $organisationId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('addressJson: $addressJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(placeId, organisationId, name, code,
      pendingSync, pendingDelete, typeConceptId, addressJson, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LieuCache &&
          other.placeId == this.placeId &&
          other.organisationId == this.organisationId &&
          other.name == this.name &&
          other.code == this.code &&
          other.pendingSync == this.pendingSync &&
          other.pendingDelete == this.pendingDelete &&
          other.typeConceptId == this.typeConceptId &&
          other.addressJson == this.addressJson &&
          other.syncedAt == this.syncedAt);
}

class LieuxCompanion extends UpdateCompanion<LieuCache> {
  final Value<int> placeId;
  final Value<int> organisationId;
  final Value<String> name;
  final Value<String?> code;
  final Value<bool> pendingSync;
  final Value<bool> pendingDelete;
  final Value<int?> typeConceptId;
  final Value<String?> addressJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const LieuxCompanion({
    this.placeId = const Value.absent(),
    this.organisationId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.typeConceptId = const Value.absent(),
    this.addressJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LieuxCompanion.insert({
    required int placeId,
    required int organisationId,
    required String name,
    this.code = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.typeConceptId = const Value.absent(),
    this.addressJson = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  })  : placeId = Value(placeId),
        organisationId = Value(organisationId),
        name = Value(name),
        syncedAt = Value(syncedAt);
  static Insertable<LieuCache> custom({
    Expression<int>? placeId,
    Expression<int>? organisationId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<bool>? pendingSync,
    Expression<bool>? pendingDelete,
    Expression<int>? typeConceptId,
    Expression<String>? addressJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (placeId != null) 'place_id': placeId,
      if (organisationId != null) 'organisation_id': organisationId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (typeConceptId != null) 'type_concept_id': typeConceptId,
      if (addressJson != null) 'address_json': addressJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LieuxCompanion copyWith(
      {Value<int>? placeId,
      Value<int>? organisationId,
      Value<String>? name,
      Value<String?>? code,
      Value<bool>? pendingSync,
      Value<bool>? pendingDelete,
      Value<int?>? typeConceptId,
      Value<String?>? addressJson,
      Value<DateTime>? syncedAt,
      Value<int>? rowid}) {
    return LieuxCompanion(
      placeId: placeId ?? this.placeId,
      organisationId: organisationId ?? this.organisationId,
      name: name ?? this.name,
      code: code ?? this.code,
      pendingSync: pendingSync ?? this.pendingSync,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      typeConceptId: typeConceptId ?? this.typeConceptId,
      addressJson: addressJson ?? this.addressJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placeId.present) {
      map['place_id'] = Variable<int>(placeId.value);
    }
    if (organisationId.present) {
      map['organisation_id'] = Variable<int>(organisationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (typeConceptId.present) {
      map['type_concept_id'] = Variable<int>(typeConceptId.value);
    }
    if (addressJson.present) {
      map['address_json'] = Variable<String>(addressJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LieuxCompanion(')
          ..write('placeId: $placeId, ')
          ..write('organisationId: $organisationId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('typeConceptId: $typeConceptId, ')
          ..write('addressJson: $addressJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrganisationsTable organisations = $OrganisationsTable(this);
  late final $UtilisateursTable utilisateurs = $UtilisateursTable(this);
  late final $FormsTable forms = $FormsTable(this);
  late final $ProjetsTable projets = $ProjetsTable(this);
  late final $ProjetsDetailTable projetsDetail = $ProjetsDetailTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DocumentsTmpTable documentsTmp = $DocumentsTmpTable(this);
  late final $DocumentsUniteEnregistrementTable documentsUniteEnregistrement =
      $DocumentsUniteEnregistrementTable(this);
  late final $UnitesEnregistrementTable unitesEnregistrement =
      $UnitesEnregistrementTable(this);
  late final $UnitesEnregistrementDetailTable unitesEnregistrementDetail =
      $UnitesEnregistrementDetailTable(this);
  late final $SyncActionsTable syncActions = $SyncActionsTable(this);
  late final $EntitySyncSnapshotsTable entitySyncSnapshots =
      $EntitySyncSnapshotsTable(this);
  late final $MobiliersTable mobiliers = $MobiliersTable(this);
  late final $MobiliersDetailTable mobiliersDetail =
      $MobiliersDetailTable(this);
  late final $ThesaurusSettingsTable thesaurusSettings =
      $ThesaurusSettingsTable(this);
  late final $LieuxTable lieux = $LieuxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        organisations,
        utilisateurs,
        forms,
        projets,
        projetsDetail,
        documents,
        documentsTmp,
        documentsUniteEnregistrement,
        unitesEnregistrement,
        unitesEnregistrementDetail,
        syncActions,
        entitySyncSnapshots,
        mobiliers,
        mobiliersDetail,
        thesaurusSettings,
        lieux
      ];
}

typedef $$OrganisationsTableCreateCompanionBuilder = OrganisationsCompanion
    Function({
  Value<int> id,
  required String nom,
});
typedef $$OrganisationsTableUpdateCompanionBuilder = OrganisationsCompanion
    Function({
  Value<int> id,
  Value<String> nom,
});

final class $$OrganisationsTableReferences
    extends BaseReferences<_$AppDatabase, $OrganisationsTable, Organisation> {
  $$OrganisationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UtilisateursTable, List<Utilisateur>>
      _utilisateursRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.utilisateurs,
              aliasName: $_aliasNameGenerator(
                  db.organisations.id, db.utilisateurs.idOrganisation));

  $$UtilisateursTableProcessedTableManager get utilisateursRefs {
    final manager = $$UtilisateursTableTableManager($_db, $_db.utilisateurs)
        .filter((f) => f.idOrganisation.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_utilisateursRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FormsTable, List<Form>> _formsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.forms,
          aliasName: $_aliasNameGenerator(
              db.organisations.id, db.forms.idOrganisation));

  $$FormsTableProcessedTableManager get formsRefs {
    final manager = $$FormsTableTableManager($_db, $_db.forms)
        .filter((f) => f.idOrganisation.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_formsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProjetsTable, List<Projet>> _projetsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.projets,
          aliasName: $_aliasNameGenerator(
              db.organisations.id, db.projets.idOrganisation));

  $$ProjetsTableProcessedTableManager get projetsRefs {
    final manager = $$ProjetsTableTableManager($_db, $_db.projets)
        .filter((f) => f.idOrganisation.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_projetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ThesaurusSettingsTable, List<ThesaurusSettingRow>>
      _thesaurusSettingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.thesaurusSettings,
              aliasName: $_aliasNameGenerator(
                  db.organisations.id, db.thesaurusSettings.organisationId));

  $$ThesaurusSettingsTableProcessedTableManager get thesaurusSettingsRefs {
    final manager = $$ThesaurusSettingsTableTableManager(
            $_db, $_db.thesaurusSettings)
        .filter((f) => f.organisationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_thesaurusSettingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LieuxTable, List<LieuCache>> _lieuxRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lieux,
          aliasName: $_aliasNameGenerator(
              db.organisations.id, db.lieux.organisationId));

  $$LieuxTableProcessedTableManager get lieuxRefs {
    final manager = $$LieuxTableTableManager($_db, $_db.lieux)
        .filter((f) => f.organisationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lieuxRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrganisationsTableFilterComposer
    extends Composer<_$AppDatabase, $OrganisationsTable> {
  $$OrganisationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnFilters(column));

  Expression<bool> utilisateursRefs(
      Expression<bool> Function($$UtilisateursTableFilterComposer f) f) {
    final $$UtilisateursTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.utilisateurs,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UtilisateursTableFilterComposer(
              $db: $db,
              $table: $db.utilisateurs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> formsRefs(
      Expression<bool> Function($$FormsTableFilterComposer f) f) {
    final $$FormsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.forms,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FormsTableFilterComposer(
              $db: $db,
              $table: $db.forms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> projetsRefs(
      Expression<bool> Function($$ProjetsTableFilterComposer f) f) {
    final $$ProjetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.projets,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjetsTableFilterComposer(
              $db: $db,
              $table: $db.projets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> thesaurusSettingsRefs(
      Expression<bool> Function($$ThesaurusSettingsTableFilterComposer f) f) {
    final $$ThesaurusSettingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.thesaurusSettings,
        getReferencedColumn: (t) => t.organisationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ThesaurusSettingsTableFilterComposer(
              $db: $db,
              $table: $db.thesaurusSettings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> lieuxRefs(
      Expression<bool> Function($$LieuxTableFilterComposer f) f) {
    final $$LieuxTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lieux,
        getReferencedColumn: (t) => t.organisationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LieuxTableFilterComposer(
              $db: $db,
              $table: $db.lieux,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrganisationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrganisationsTable> {
  $$OrganisationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnOrderings(column));
}

class $$OrganisationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrganisationsTable> {
  $$OrganisationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  Expression<T> utilisateursRefs<T extends Object>(
      Expression<T> Function($$UtilisateursTableAnnotationComposer a) f) {
    final $$UtilisateursTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.utilisateurs,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UtilisateursTableAnnotationComposer(
              $db: $db,
              $table: $db.utilisateurs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> formsRefs<T extends Object>(
      Expression<T> Function($$FormsTableAnnotationComposer a) f) {
    final $$FormsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.forms,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FormsTableAnnotationComposer(
              $db: $db,
              $table: $db.forms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> projetsRefs<T extends Object>(
      Expression<T> Function($$ProjetsTableAnnotationComposer a) f) {
    final $$ProjetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.projets,
        getReferencedColumn: (t) => t.idOrganisation,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjetsTableAnnotationComposer(
              $db: $db,
              $table: $db.projets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> thesaurusSettingsRefs<T extends Object>(
      Expression<T> Function($$ThesaurusSettingsTableAnnotationComposer a) f) {
    final $$ThesaurusSettingsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.thesaurusSettings,
            getReferencedColumn: (t) => t.organisationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ThesaurusSettingsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.thesaurusSettings,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> lieuxRefs<T extends Object>(
      Expression<T> Function($$LieuxTableAnnotationComposer a) f) {
    final $$LieuxTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lieux,
        getReferencedColumn: (t) => t.organisationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LieuxTableAnnotationComposer(
              $db: $db,
              $table: $db.lieux,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrganisationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrganisationsTable,
    Organisation,
    $$OrganisationsTableFilterComposer,
    $$OrganisationsTableOrderingComposer,
    $$OrganisationsTableAnnotationComposer,
    $$OrganisationsTableCreateCompanionBuilder,
    $$OrganisationsTableUpdateCompanionBuilder,
    (Organisation, $$OrganisationsTableReferences),
    Organisation,
    PrefetchHooks Function(
        {bool utilisateursRefs,
        bool formsRefs,
        bool projetsRefs,
        bool thesaurusSettingsRefs,
        bool lieuxRefs})> {
  $$OrganisationsTableTableManager(_$AppDatabase db, $OrganisationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganisationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganisationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganisationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nom = const Value.absent(),
          }) =>
              OrganisationsCompanion(
            id: id,
            nom: nom,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nom,
          }) =>
              OrganisationsCompanion.insert(
            id: id,
            nom: nom,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OrganisationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {utilisateursRefs = false,
              formsRefs = false,
              projetsRefs = false,
              thesaurusSettingsRefs = false,
              lieuxRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (utilisateursRefs) db.utilisateurs,
                if (formsRefs) db.forms,
                if (projetsRefs) db.projets,
                if (thesaurusSettingsRefs) db.thesaurusSettings,
                if (lieuxRefs) db.lieux
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (utilisateursRefs)
                    await $_getPrefetchedData<Organisation, $OrganisationsTable,
                            Utilisateur>(
                        currentTable: table,
                        referencedTable: $$OrganisationsTableReferences
                            ._utilisateursRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrganisationsTableReferences(db, table, p0)
                                .utilisateursRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.idOrganisation == item.id),
                        typedResults: items),
                  if (formsRefs)
                    await $_getPrefetchedData<Organisation, $OrganisationsTable,
                            Form>(
                        currentTable: table,
                        referencedTable:
                            $$OrganisationsTableReferences._formsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrganisationsTableReferences(db, table, p0)
                                .formsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.idOrganisation == item.id),
                        typedResults: items),
                  if (projetsRefs)
                    await $_getPrefetchedData<Organisation, $OrganisationsTable,
                            Projet>(
                        currentTable: table,
                        referencedTable: $$OrganisationsTableReferences
                            ._projetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrganisationsTableReferences(db, table, p0)
                                .projetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.idOrganisation == item.id),
                        typedResults: items),
                  if (thesaurusSettingsRefs)
                    await $_getPrefetchedData<Organisation, $OrganisationsTable,
                            ThesaurusSettingRow>(
                        currentTable: table,
                        referencedTable: $$OrganisationsTableReferences
                            ._thesaurusSettingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrganisationsTableReferences(db, table, p0)
                                .thesaurusSettingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.organisationId == item.id),
                        typedResults: items),
                  if (lieuxRefs)
                    await $_getPrefetchedData<Organisation, $OrganisationsTable,
                            LieuCache>(
                        currentTable: table,
                        referencedTable:
                            $$OrganisationsTableReferences._lieuxRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrganisationsTableReferences(db, table, p0)
                                .lieuxRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.organisationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrganisationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrganisationsTable,
    Organisation,
    $$OrganisationsTableFilterComposer,
    $$OrganisationsTableOrderingComposer,
    $$OrganisationsTableAnnotationComposer,
    $$OrganisationsTableCreateCompanionBuilder,
    $$OrganisationsTableUpdateCompanionBuilder,
    (Organisation, $$OrganisationsTableReferences),
    Organisation,
    PrefetchHooks Function(
        {bool utilisateursRefs,
        bool formsRefs,
        bool projetsRefs,
        bool thesaurusSettingsRefs,
        bool lieuxRefs})>;
typedef $$UtilisateursTableCreateCompanionBuilder = UtilisateursCompanion
    Function({
  Value<int> id,
  Value<int?> apiPersonId,
  required String nom,
  required String prenom,
  required String email,
  required String username,
  required String password,
  required int idOrganisation,
});
typedef $$UtilisateursTableUpdateCompanionBuilder = UtilisateursCompanion
    Function({
  Value<int> id,
  Value<int?> apiPersonId,
  Value<String> nom,
  Value<String> prenom,
  Value<String> email,
  Value<String> username,
  Value<String> password,
  Value<int> idOrganisation,
});

final class $$UtilisateursTableReferences
    extends BaseReferences<_$AppDatabase, $UtilisateursTable, Utilisateur> {
  $$UtilisateursTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrganisationsTable _idOrganisationTable(_$AppDatabase db) =>
      db.organisations.createAlias($_aliasNameGenerator(
          db.utilisateurs.idOrganisation, db.organisations.id));

  $$OrganisationsTableProcessedTableManager get idOrganisation {
    final $_column = $_itemColumn<int>('id_organisation')!;

    final manager = $$OrganisationsTableTableManager($_db, $_db.organisations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idOrganisationTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UtilisateursTableFilterComposer
    extends Composer<_$AppDatabase, $UtilisateursTable> {
  $$UtilisateursTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get apiPersonId => $composableBuilder(
      column: $table.apiPersonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prenom => $composableBuilder(
      column: $table.prenom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  $$OrganisationsTableFilterComposer get idOrganisation {
    final $$OrganisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableFilterComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UtilisateursTableOrderingComposer
    extends Composer<_$AppDatabase, $UtilisateursTable> {
  $$UtilisateursTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get apiPersonId => $composableBuilder(
      column: $table.apiPersonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prenom => $composableBuilder(
      column: $table.prenom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  $$OrganisationsTableOrderingComposer get idOrganisation {
    final $$OrganisationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableOrderingComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UtilisateursTableAnnotationComposer
    extends Composer<_$AppDatabase, $UtilisateursTable> {
  $$UtilisateursTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get apiPersonId => $composableBuilder(
      column: $table.apiPersonId, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get prenom =>
      $composableBuilder(column: $table.prenom, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  $$OrganisationsTableAnnotationComposer get idOrganisation {
    final $$OrganisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UtilisateursTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UtilisateursTable,
    Utilisateur,
    $$UtilisateursTableFilterComposer,
    $$UtilisateursTableOrderingComposer,
    $$UtilisateursTableAnnotationComposer,
    $$UtilisateursTableCreateCompanionBuilder,
    $$UtilisateursTableUpdateCompanionBuilder,
    (Utilisateur, $$UtilisateursTableReferences),
    Utilisateur,
    PrefetchHooks Function({bool idOrganisation})> {
  $$UtilisateursTableTableManager(_$AppDatabase db, $UtilisateursTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UtilisateursTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UtilisateursTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UtilisateursTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> apiPersonId = const Value.absent(),
            Value<String> nom = const Value.absent(),
            Value<String> prenom = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> password = const Value.absent(),
            Value<int> idOrganisation = const Value.absent(),
          }) =>
              UtilisateursCompanion(
            id: id,
            apiPersonId: apiPersonId,
            nom: nom,
            prenom: prenom,
            email: email,
            username: username,
            password: password,
            idOrganisation: idOrganisation,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> apiPersonId = const Value.absent(),
            required String nom,
            required String prenom,
            required String email,
            required String username,
            required String password,
            required int idOrganisation,
          }) =>
              UtilisateursCompanion.insert(
            id: id,
            apiPersonId: apiPersonId,
            nom: nom,
            prenom: prenom,
            email: email,
            username: username,
            password: password,
            idOrganisation: idOrganisation,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UtilisateursTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({idOrganisation = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (idOrganisation) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.idOrganisation,
                    referencedTable:
                        $$UtilisateursTableReferences._idOrganisationTable(db),
                    referencedColumn: $$UtilisateursTableReferences
                        ._idOrganisationTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UtilisateursTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UtilisateursTable,
    Utilisateur,
    $$UtilisateursTableFilterComposer,
    $$UtilisateursTableOrderingComposer,
    $$UtilisateursTableAnnotationComposer,
    $$UtilisateursTableCreateCompanionBuilder,
    $$UtilisateursTableUpdateCompanionBuilder,
    (Utilisateur, $$UtilisateursTableReferences),
    Utilisateur,
    PrefetchHooks Function({bool idOrganisation})>;
typedef $$FormsTableCreateCompanionBuilder = FormsCompanion Function({
  Value<int> id,
  required String type,
  required String contenu,
  required int ttl,
  required DateTime creationDate,
  required int idOrganisation,
});
typedef $$FormsTableUpdateCompanionBuilder = FormsCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<String> contenu,
  Value<int> ttl,
  Value<DateTime> creationDate,
  Value<int> idOrganisation,
});

final class $$FormsTableReferences
    extends BaseReferences<_$AppDatabase, $FormsTable, Form> {
  $$FormsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrganisationsTable _idOrganisationTable(_$AppDatabase db) =>
      db.organisations.createAlias(
          $_aliasNameGenerator(db.forms.idOrganisation, db.organisations.id));

  $$OrganisationsTableProcessedTableManager get idOrganisation {
    final $_column = $_itemColumn<int>('id_organisation')!;

    final manager = $$OrganisationsTableTableManager($_db, $_db.organisations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idOrganisationTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FormsTableFilterComposer extends Composer<_$AppDatabase, $FormsTable> {
  $$FormsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contenu => $composableBuilder(
      column: $table.contenu, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ttl => $composableBuilder(
      column: $table.ttl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get creationDate => $composableBuilder(
      column: $table.creationDate, builder: (column) => ColumnFilters(column));

  $$OrganisationsTableFilterComposer get idOrganisation {
    final $$OrganisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableFilterComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FormsTableOrderingComposer
    extends Composer<_$AppDatabase, $FormsTable> {
  $$FormsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contenu => $composableBuilder(
      column: $table.contenu, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ttl => $composableBuilder(
      column: $table.ttl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get creationDate => $composableBuilder(
      column: $table.creationDate,
      builder: (column) => ColumnOrderings(column));

  $$OrganisationsTableOrderingComposer get idOrganisation {
    final $$OrganisationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableOrderingComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FormsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormsTable> {
  $$FormsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get contenu =>
      $composableBuilder(column: $table.contenu, builder: (column) => column);

  GeneratedColumn<int> get ttl =>
      $composableBuilder(column: $table.ttl, builder: (column) => column);

  GeneratedColumn<DateTime> get creationDate => $composableBuilder(
      column: $table.creationDate, builder: (column) => column);

  $$OrganisationsTableAnnotationComposer get idOrganisation {
    final $$OrganisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FormsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FormsTable,
    Form,
    $$FormsTableFilterComposer,
    $$FormsTableOrderingComposer,
    $$FormsTableAnnotationComposer,
    $$FormsTableCreateCompanionBuilder,
    $$FormsTableUpdateCompanionBuilder,
    (Form, $$FormsTableReferences),
    Form,
    PrefetchHooks Function({bool idOrganisation})> {
  $$FormsTableTableManager(_$AppDatabase db, $FormsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> contenu = const Value.absent(),
            Value<int> ttl = const Value.absent(),
            Value<DateTime> creationDate = const Value.absent(),
            Value<int> idOrganisation = const Value.absent(),
          }) =>
              FormsCompanion(
            id: id,
            type: type,
            contenu: contenu,
            ttl: ttl,
            creationDate: creationDate,
            idOrganisation: idOrganisation,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required String contenu,
            required int ttl,
            required DateTime creationDate,
            required int idOrganisation,
          }) =>
              FormsCompanion.insert(
            id: id,
            type: type,
            contenu: contenu,
            ttl: ttl,
            creationDate: creationDate,
            idOrganisation: idOrganisation,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$FormsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({idOrganisation = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (idOrganisation) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.idOrganisation,
                    referencedTable:
                        $$FormsTableReferences._idOrganisationTable(db),
                    referencedColumn:
                        $$FormsTableReferences._idOrganisationTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FormsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FormsTable,
    Form,
    $$FormsTableFilterComposer,
    $$FormsTableOrderingComposer,
    $$FormsTableAnnotationComposer,
    $$FormsTableCreateCompanionBuilder,
    $$FormsTableUpdateCompanionBuilder,
    (Form, $$FormsTableReferences),
    Form,
    PrefetchHooks Function({bool idOrganisation})>;
typedef $$ProjetsTableCreateCompanionBuilder = ProjetsCompanion Function({
  required String id,
  required String nom,
  Value<String?> identifiant,
  Value<String?> fullIdentifier,
  Value<int?> recordingUnitCount,
  required int idOrganisation,
  Value<int> rowid,
});
typedef $$ProjetsTableUpdateCompanionBuilder = ProjetsCompanion Function({
  Value<String> id,
  Value<String> nom,
  Value<String?> identifiant,
  Value<String?> fullIdentifier,
  Value<int?> recordingUnitCount,
  Value<int> idOrganisation,
  Value<int> rowid,
});

final class $$ProjetsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjetsTable, Projet> {
  $$ProjetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrganisationsTable _idOrganisationTable(_$AppDatabase db) =>
      db.organisations.createAlias(
          $_aliasNameGenerator(db.projets.idOrganisation, db.organisations.id));

  $$OrganisationsTableProcessedTableManager get idOrganisation {
    final $_column = $_itemColumn<int>('id_organisation')!;

    final manager = $$OrganisationsTableTableManager($_db, $_db.organisations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_idOrganisationTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProjetsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjetsTable> {
  $$ProjetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifiant => $composableBuilder(
      column: $table.identifiant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullIdentifier => $composableBuilder(
      column: $table.fullIdentifier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordingUnitCount => $composableBuilder(
      column: $table.recordingUnitCount,
      builder: (column) => ColumnFilters(column));

  $$OrganisationsTableFilterComposer get idOrganisation {
    final $$OrganisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableFilterComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjetsTable> {
  $$ProjetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nom => $composableBuilder(
      column: $table.nom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifiant => $composableBuilder(
      column: $table.identifiant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullIdentifier => $composableBuilder(
      column: $table.fullIdentifier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordingUnitCount => $composableBuilder(
      column: $table.recordingUnitCount,
      builder: (column) => ColumnOrderings(column));

  $$OrganisationsTableOrderingComposer get idOrganisation {
    final $$OrganisationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableOrderingComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjetsTable> {
  $$ProjetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get identifiant => $composableBuilder(
      column: $table.identifiant, builder: (column) => column);

  GeneratedColumn<String> get fullIdentifier => $composableBuilder(
      column: $table.fullIdentifier, builder: (column) => column);

  GeneratedColumn<int> get recordingUnitCount => $composableBuilder(
      column: $table.recordingUnitCount, builder: (column) => column);

  $$OrganisationsTableAnnotationComposer get idOrganisation {
    final $$OrganisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.idOrganisation,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProjetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjetsTable,
    Projet,
    $$ProjetsTableFilterComposer,
    $$ProjetsTableOrderingComposer,
    $$ProjetsTableAnnotationComposer,
    $$ProjetsTableCreateCompanionBuilder,
    $$ProjetsTableUpdateCompanionBuilder,
    (Projet, $$ProjetsTableReferences),
    Projet,
    PrefetchHooks Function({bool idOrganisation})> {
  $$ProjetsTableTableManager(_$AppDatabase db, $ProjetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> nom = const Value.absent(),
            Value<String?> identifiant = const Value.absent(),
            Value<String?> fullIdentifier = const Value.absent(),
            Value<int?> recordingUnitCount = const Value.absent(),
            Value<int> idOrganisation = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjetsCompanion(
            id: id,
            nom: nom,
            identifiant: identifiant,
            fullIdentifier: fullIdentifier,
            recordingUnitCount: recordingUnitCount,
            idOrganisation: idOrganisation,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String nom,
            Value<String?> identifiant = const Value.absent(),
            Value<String?> fullIdentifier = const Value.absent(),
            Value<int?> recordingUnitCount = const Value.absent(),
            required int idOrganisation,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjetsCompanion.insert(
            id: id,
            nom: nom,
            identifiant: identifiant,
            fullIdentifier: fullIdentifier,
            recordingUnitCount: recordingUnitCount,
            idOrganisation: idOrganisation,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({idOrganisation = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (idOrganisation) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.idOrganisation,
                    referencedTable:
                        $$ProjetsTableReferences._idOrganisationTable(db),
                    referencedColumn:
                        $$ProjetsTableReferences._idOrganisationTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProjetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjetsTable,
    Projet,
    $$ProjetsTableFilterComposer,
    $$ProjetsTableOrderingComposer,
    $$ProjetsTableAnnotationComposer,
    $$ProjetsTableCreateCompanionBuilder,
    $$ProjetsTableUpdateCompanionBuilder,
    (Projet, $$ProjetsTableReferences),
    Projet,
    PrefetchHooks Function({bool idOrganisation})>;
typedef $$ProjetsDetailTableCreateCompanionBuilder = ProjetsDetailCompanion
    Function({
  required String resourceId,
  required String detailJson,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$ProjetsDetailTableUpdateCompanionBuilder = ProjetsDetailCompanion
    Function({
  Value<String> resourceId,
  Value<String> detailJson,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$ProjetsDetailTableFilterComposer
    extends Composer<_$AppDatabase, $ProjetsDetailTable> {
  $$ProjetsDetailTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$ProjetsDetailTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjetsDetailTable> {
  $$ProjetsDetailTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjetsDetailTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjetsDetailTable> {
  $$ProjetsDetailTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ProjetsDetailTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjetsDetailTable,
    ProjetDetailRow,
    $$ProjetsDetailTableFilterComposer,
    $$ProjetsDetailTableOrderingComposer,
    $$ProjetsDetailTableAnnotationComposer,
    $$ProjetsDetailTableCreateCompanionBuilder,
    $$ProjetsDetailTableUpdateCompanionBuilder,
    (
      ProjetDetailRow,
      BaseReferences<_$AppDatabase, $ProjetsDetailTable, ProjetDetailRow>
    ),
    ProjetDetailRow,
    PrefetchHooks Function()> {
  $$ProjetsDetailTableTableManager(_$AppDatabase db, $ProjetsDetailTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjetsDetailTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjetsDetailTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjetsDetailTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> detailJson = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjetsDetailCompanion(
            resourceId: resourceId,
            detailJson: detailJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String detailJson,
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjetsDetailCompanion.insert(
            resourceId: resourceId,
            detailJson: detailJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjetsDetailTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjetsDetailTable,
    ProjetDetailRow,
    $$ProjetsDetailTableFilterComposer,
    $$ProjetsDetailTableOrderingComposer,
    $$ProjetsDetailTableAnnotationComposer,
    $$ProjetsDetailTableCreateCompanionBuilder,
    $$ProjetsDetailTableUpdateCompanionBuilder,
    (
      ProjetDetailRow,
      BaseReferences<_$AppDatabase, $ProjetsDetailTable, ProjetDetailRow>
    ),
    ProjetDetailRow,
    PrefetchHooks Function()>;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  required String resourceId,
  required String titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> url,
  Value<String?> fileCode,
  required String projectId,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> resourceId,
  Value<String> titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> url,
  Value<String?> fileCode,
  Value<String> projectId,
  Value<int> rowid,
});

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get titre =>
      $composableBuilder(column: $table.titre, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get fileCode =>
      $composableBuilder(column: $table.fileCode, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);
}

class $$DocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()> {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> titre = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion(
            resourceId: resourceId,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            url: url,
            fileCode: fileCode,
            projectId: projectId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String titre,
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            required String projectId,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            resourceId: resourceId,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            url: url,
            fileCode: fileCode,
            projectId: projectId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$AppDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()>;
typedef $$DocumentsTmpTableCreateCompanionBuilder = DocumentsTmpCompanion
    Function({
  required String localId,
  Value<String?> resourceId,
  required String parentType,
  required String parentId,
  required String kind,
  required String status,
  required String titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> fileCode,
  Value<String?> url,
  Value<int?> natureConceptId,
  Value<int?> scaleConceptId,
  Value<int?> formatConceptId,
  required Uint8List fileContent,
  Value<int> fileSize,
  Value<String?> uploadError,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DocumentsTmpTableUpdateCompanionBuilder = DocumentsTmpCompanion
    Function({
  Value<String> localId,
  Value<String?> resourceId,
  Value<String> parentType,
  Value<String> parentId,
  Value<String> kind,
  Value<String> status,
  Value<String> titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> fileCode,
  Value<String?> url,
  Value<int?> natureConceptId,
  Value<int?> scaleConceptId,
  Value<int?> formatConceptId,
  Value<Uint8List> fileContent,
  Value<int> fileSize,
  Value<String?> uploadError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DocumentsTmpTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTmpTable> {
  $$DocumentsTmpTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get natureConceptId => $composableBuilder(
      column: $table.natureConceptId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scaleConceptId => $composableBuilder(
      column: $table.scaleConceptId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get formatConceptId => $composableBuilder(
      column: $table.formatConceptId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get fileContent => $composableBuilder(
      column: $table.fileContent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploadError => $composableBuilder(
      column: $table.uploadError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DocumentsTmpTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTmpTable> {
  $$DocumentsTmpTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get natureConceptId => $composableBuilder(
      column: $table.natureConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scaleConceptId => $composableBuilder(
      column: $table.scaleConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get formatConceptId => $composableBuilder(
      column: $table.formatConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get fileContent => $composableBuilder(
      column: $table.fileContent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadError => $composableBuilder(
      column: $table.uploadError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DocumentsTmpTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTmpTable> {
  $$DocumentsTmpTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get titre =>
      $composableBuilder(column: $table.titre, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get fileCode =>
      $composableBuilder(column: $table.fileCode, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get natureConceptId => $composableBuilder(
      column: $table.natureConceptId, builder: (column) => column);

  GeneratedColumn<int> get scaleConceptId => $composableBuilder(
      column: $table.scaleConceptId, builder: (column) => column);

  GeneratedColumn<int> get formatConceptId => $composableBuilder(
      column: $table.formatConceptId, builder: (column) => column);

  GeneratedColumn<Uint8List> get fileContent => $composableBuilder(
      column: $table.fileContent, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get uploadError => $composableBuilder(
      column: $table.uploadError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DocumentsTmpTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsTmpTable,
    DocumentTmpRow,
    $$DocumentsTmpTableFilterComposer,
    $$DocumentsTmpTableOrderingComposer,
    $$DocumentsTmpTableAnnotationComposer,
    $$DocumentsTmpTableCreateCompanionBuilder,
    $$DocumentsTmpTableUpdateCompanionBuilder,
    (
      DocumentTmpRow,
      BaseReferences<_$AppDatabase, $DocumentsTmpTable, DocumentTmpRow>
    ),
    DocumentTmpRow,
    PrefetchHooks Function()> {
  $$DocumentsTmpTableTableManager(_$AppDatabase db, $DocumentsTmpTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTmpTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTmpTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTmpTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> resourceId = const Value.absent(),
            Value<String> parentType = const Value.absent(),
            Value<String> parentId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> titre = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<int?> natureConceptId = const Value.absent(),
            Value<int?> scaleConceptId = const Value.absent(),
            Value<int?> formatConceptId = const Value.absent(),
            Value<Uint8List> fileContent = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<String?> uploadError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsTmpCompanion(
            localId: localId,
            resourceId: resourceId,
            parentType: parentType,
            parentId: parentId,
            kind: kind,
            status: status,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            fileCode: fileCode,
            url: url,
            natureConceptId: natureConceptId,
            scaleConceptId: scaleConceptId,
            formatConceptId: formatConceptId,
            fileContent: fileContent,
            fileSize: fileSize,
            uploadError: uploadError,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            Value<String?> resourceId = const Value.absent(),
            required String parentType,
            required String parentId,
            required String kind,
            required String status,
            required String titre,
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<int?> natureConceptId = const Value.absent(),
            Value<int?> scaleConceptId = const Value.absent(),
            Value<int?> formatConceptId = const Value.absent(),
            required Uint8List fileContent,
            Value<int> fileSize = const Value.absent(),
            Value<String?> uploadError = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsTmpCompanion.insert(
            localId: localId,
            resourceId: resourceId,
            parentType: parentType,
            parentId: parentId,
            kind: kind,
            status: status,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            fileCode: fileCode,
            url: url,
            natureConceptId: natureConceptId,
            scaleConceptId: scaleConceptId,
            formatConceptId: formatConceptId,
            fileContent: fileContent,
            fileSize: fileSize,
            uploadError: uploadError,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsTmpTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentsTmpTable,
    DocumentTmpRow,
    $$DocumentsTmpTableFilterComposer,
    $$DocumentsTmpTableOrderingComposer,
    $$DocumentsTmpTableAnnotationComposer,
    $$DocumentsTmpTableCreateCompanionBuilder,
    $$DocumentsTmpTableUpdateCompanionBuilder,
    (
      DocumentTmpRow,
      BaseReferences<_$AppDatabase, $DocumentsTmpTable, DocumentTmpRow>
    ),
    DocumentTmpRow,
    PrefetchHooks Function()>;
typedef $$DocumentsUniteEnregistrementTableCreateCompanionBuilder
    = DocumentsUniteEnregistrementCompanion Function({
  required String resourceId,
  required String titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> url,
  Value<String?> fileCode,
  required String uniteEnregistrementId,
  Value<int> rowid,
});
typedef $$DocumentsUniteEnregistrementTableUpdateCompanionBuilder
    = DocumentsUniteEnregistrementCompanion Function({
  Value<String> resourceId,
  Value<String> titre,
  Value<String?> description,
  Value<String?> fileName,
  Value<String?> mimeType,
  Value<String?> url,
  Value<String?> fileCode,
  Value<String> uniteEnregistrementId,
  Value<int> rowid,
});

class $$DocumentsUniteEnregistrementTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsUniteEnregistrementTable> {
  $$DocumentsUniteEnregistrementTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnFilters(column));
}

class $$DocumentsUniteEnregistrementTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsUniteEnregistrementTable> {
  $$DocumentsUniteEnregistrementTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titre => $composableBuilder(
      column: $table.titre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileCode => $composableBuilder(
      column: $table.fileCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnOrderings(column));
}

class $$DocumentsUniteEnregistrementTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsUniteEnregistrementTable> {
  $$DocumentsUniteEnregistrementTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get titre =>
      $composableBuilder(column: $table.titre, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get fileCode =>
      $composableBuilder(column: $table.fileCode, builder: (column) => column);

  GeneratedColumn<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId, builder: (column) => column);
}

class $$DocumentsUniteEnregistrementTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsUniteEnregistrementTable,
    DocumentUniteEnregistrement,
    $$DocumentsUniteEnregistrementTableFilterComposer,
    $$DocumentsUniteEnregistrementTableOrderingComposer,
    $$DocumentsUniteEnregistrementTableAnnotationComposer,
    $$DocumentsUniteEnregistrementTableCreateCompanionBuilder,
    $$DocumentsUniteEnregistrementTableUpdateCompanionBuilder,
    (
      DocumentUniteEnregistrement,
      BaseReferences<_$AppDatabase, $DocumentsUniteEnregistrementTable,
          DocumentUniteEnregistrement>
    ),
    DocumentUniteEnregistrement,
    PrefetchHooks Function()> {
  $$DocumentsUniteEnregistrementTableTableManager(
      _$AppDatabase db, $DocumentsUniteEnregistrementTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsUniteEnregistrementTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsUniteEnregistrementTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsUniteEnregistrementTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> titre = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            Value<String> uniteEnregistrementId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsUniteEnregistrementCompanion(
            resourceId: resourceId,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            url: url,
            fileCode: fileCode,
            uniteEnregistrementId: uniteEnregistrementId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String titre,
            Value<String?> description = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> fileCode = const Value.absent(),
            required String uniteEnregistrementId,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsUniteEnregistrementCompanion.insert(
            resourceId: resourceId,
            titre: titre,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            url: url,
            fileCode: fileCode,
            uniteEnregistrementId: uniteEnregistrementId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsUniteEnregistrementTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DocumentsUniteEnregistrementTable,
        DocumentUniteEnregistrement,
        $$DocumentsUniteEnregistrementTableFilterComposer,
        $$DocumentsUniteEnregistrementTableOrderingComposer,
        $$DocumentsUniteEnregistrementTableAnnotationComposer,
        $$DocumentsUniteEnregistrementTableCreateCompanionBuilder,
        $$DocumentsUniteEnregistrementTableUpdateCompanionBuilder,
        (
          DocumentUniteEnregistrement,
          BaseReferences<_$AppDatabase, $DocumentsUniteEnregistrementTable,
              DocumentUniteEnregistrement>
        ),
        DocumentUniteEnregistrement,
        PrefetchHooks Function()>;
typedef $$UnitesEnregistrementTableCreateCompanionBuilder
    = UnitesEnregistrementCompanion Function({
  required String resourceId,
  required String projectId,
  required String displayCode,
  Value<String?> identifier,
  Value<String?> typeLabel,
  Value<String?> placeLabel,
  Value<DateTime?> openingDate,
  Value<DateTime?> closingDate,
  Value<String?> matrixColor,
  Value<int?> specimenCount,
  Value<int?> stratigraphicCount,
  Value<int?> typeConceptId,
  Value<String?> parentIdsJson,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$UnitesEnregistrementTableUpdateCompanionBuilder
    = UnitesEnregistrementCompanion Function({
  Value<String> resourceId,
  Value<String> projectId,
  Value<String> displayCode,
  Value<String?> identifier,
  Value<String?> typeLabel,
  Value<String?> placeLabel,
  Value<DateTime?> openingDate,
  Value<DateTime?> closingDate,
  Value<String?> matrixColor,
  Value<int?> specimenCount,
  Value<int?> stratigraphicCount,
  Value<int?> typeConceptId,
  Value<String?> parentIdsJson,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$UnitesEnregistrementTableFilterComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementTable> {
  $$UnitesEnregistrementTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typeLabel => $composableBuilder(
      column: $table.typeLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeLabel => $composableBuilder(
      column: $table.placeLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closingDate => $composableBuilder(
      column: $table.closingDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matrixColor => $composableBuilder(
      column: $table.matrixColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get specimenCount => $composableBuilder(
      column: $table.specimenCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stratigraphicCount => $composableBuilder(
      column: $table.stratigraphicCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentIdsJson => $composableBuilder(
      column: $table.parentIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$UnitesEnregistrementTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementTable> {
  $$UnitesEnregistrementTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typeLabel => $composableBuilder(
      column: $table.typeLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeLabel => $composableBuilder(
      column: $table.placeLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closingDate => $composableBuilder(
      column: $table.closingDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matrixColor => $composableBuilder(
      column: $table.matrixColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get specimenCount => $composableBuilder(
      column: $table.specimenCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stratigraphicCount => $composableBuilder(
      column: $table.stratigraphicCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentIdsJson => $composableBuilder(
      column: $table.parentIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$UnitesEnregistrementTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementTable> {
  $$UnitesEnregistrementTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
      column: $table.identifier, builder: (column) => column);

  GeneratedColumn<String> get typeLabel =>
      $composableBuilder(column: $table.typeLabel, builder: (column) => column);

  GeneratedColumn<String> get placeLabel => $composableBuilder(
      column: $table.placeLabel, builder: (column) => column);

  GeneratedColumn<DateTime> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => column);

  GeneratedColumn<DateTime> get closingDate => $composableBuilder(
      column: $table.closingDate, builder: (column) => column);

  GeneratedColumn<String> get matrixColor => $composableBuilder(
      column: $table.matrixColor, builder: (column) => column);

  GeneratedColumn<int> get specimenCount => $composableBuilder(
      column: $table.specimenCount, builder: (column) => column);

  GeneratedColumn<int> get stratigraphicCount => $composableBuilder(
      column: $table.stratigraphicCount, builder: (column) => column);

  GeneratedColumn<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => column);

  GeneratedColumn<String> get parentIdsJson => $composableBuilder(
      column: $table.parentIdsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$UnitesEnregistrementTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitesEnregistrementTable,
    UniteEnregistrement,
    $$UnitesEnregistrementTableFilterComposer,
    $$UnitesEnregistrementTableOrderingComposer,
    $$UnitesEnregistrementTableAnnotationComposer,
    $$UnitesEnregistrementTableCreateCompanionBuilder,
    $$UnitesEnregistrementTableUpdateCompanionBuilder,
    (
      UniteEnregistrement,
      BaseReferences<_$AppDatabase, $UnitesEnregistrementTable,
          UniteEnregistrement>
    ),
    UniteEnregistrement,
    PrefetchHooks Function()> {
  $$UnitesEnregistrementTableTableManager(
      _$AppDatabase db, $UnitesEnregistrementTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitesEnregistrementTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitesEnregistrementTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitesEnregistrementTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> displayCode = const Value.absent(),
            Value<String?> identifier = const Value.absent(),
            Value<String?> typeLabel = const Value.absent(),
            Value<String?> placeLabel = const Value.absent(),
            Value<DateTime?> openingDate = const Value.absent(),
            Value<DateTime?> closingDate = const Value.absent(),
            Value<String?> matrixColor = const Value.absent(),
            Value<int?> specimenCount = const Value.absent(),
            Value<int?> stratigraphicCount = const Value.absent(),
            Value<int?> typeConceptId = const Value.absent(),
            Value<String?> parentIdsJson = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitesEnregistrementCompanion(
            resourceId: resourceId,
            projectId: projectId,
            displayCode: displayCode,
            identifier: identifier,
            typeLabel: typeLabel,
            placeLabel: placeLabel,
            openingDate: openingDate,
            closingDate: closingDate,
            matrixColor: matrixColor,
            specimenCount: specimenCount,
            stratigraphicCount: stratigraphicCount,
            typeConceptId: typeConceptId,
            parentIdsJson: parentIdsJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String projectId,
            required String displayCode,
            Value<String?> identifier = const Value.absent(),
            Value<String?> typeLabel = const Value.absent(),
            Value<String?> placeLabel = const Value.absent(),
            Value<DateTime?> openingDate = const Value.absent(),
            Value<DateTime?> closingDate = const Value.absent(),
            Value<String?> matrixColor = const Value.absent(),
            Value<int?> specimenCount = const Value.absent(),
            Value<int?> stratigraphicCount = const Value.absent(),
            Value<int?> typeConceptId = const Value.absent(),
            Value<String?> parentIdsJson = const Value.absent(),
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitesEnregistrementCompanion.insert(
            resourceId: resourceId,
            projectId: projectId,
            displayCode: displayCode,
            identifier: identifier,
            typeLabel: typeLabel,
            placeLabel: placeLabel,
            openingDate: openingDate,
            closingDate: closingDate,
            matrixColor: matrixColor,
            specimenCount: specimenCount,
            stratigraphicCount: stratigraphicCount,
            typeConceptId: typeConceptId,
            parentIdsJson: parentIdsJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnitesEnregistrementTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UnitesEnregistrementTable,
        UniteEnregistrement,
        $$UnitesEnregistrementTableFilterComposer,
        $$UnitesEnregistrementTableOrderingComposer,
        $$UnitesEnregistrementTableAnnotationComposer,
        $$UnitesEnregistrementTableCreateCompanionBuilder,
        $$UnitesEnregistrementTableUpdateCompanionBuilder,
        (
          UniteEnregistrement,
          BaseReferences<_$AppDatabase, $UnitesEnregistrementTable,
              UniteEnregistrement>
        ),
        UniteEnregistrement,
        PrefetchHooks Function()>;
typedef $$UnitesEnregistrementDetailTableCreateCompanionBuilder
    = UnitesEnregistrementDetailCompanion Function({
  required String resourceId,
  required String detailJson,
  Value<int?> typeConceptId,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$UnitesEnregistrementDetailTableUpdateCompanionBuilder
    = UnitesEnregistrementDetailCompanion Function({
  Value<String> resourceId,
  Value<String> detailJson,
  Value<int?> typeConceptId,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$UnitesEnregistrementDetailTableFilterComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementDetailTable> {
  $$UnitesEnregistrementDetailTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$UnitesEnregistrementDetailTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementDetailTable> {
  $$UnitesEnregistrementDetailTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$UnitesEnregistrementDetailTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitesEnregistrementDetailTable> {
  $$UnitesEnregistrementDetailTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => column);

  GeneratedColumn<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$UnitesEnregistrementDetailTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitesEnregistrementDetailTable,
    UniteEnregistrementDetailRow,
    $$UnitesEnregistrementDetailTableFilterComposer,
    $$UnitesEnregistrementDetailTableOrderingComposer,
    $$UnitesEnregistrementDetailTableAnnotationComposer,
    $$UnitesEnregistrementDetailTableCreateCompanionBuilder,
    $$UnitesEnregistrementDetailTableUpdateCompanionBuilder,
    (
      UniteEnregistrementDetailRow,
      BaseReferences<_$AppDatabase, $UnitesEnregistrementDetailTable,
          UniteEnregistrementDetailRow>
    ),
    UniteEnregistrementDetailRow,
    PrefetchHooks Function()> {
  $$UnitesEnregistrementDetailTableTableManager(
      _$AppDatabase db, $UnitesEnregistrementDetailTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitesEnregistrementDetailTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitesEnregistrementDetailTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitesEnregistrementDetailTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> detailJson = const Value.absent(),
            Value<int?> typeConceptId = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitesEnregistrementDetailCompanion(
            resourceId: resourceId,
            detailJson: detailJson,
            typeConceptId: typeConceptId,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String detailJson,
            Value<int?> typeConceptId = const Value.absent(),
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitesEnregistrementDetailCompanion.insert(
            resourceId: resourceId,
            detailJson: detailJson,
            typeConceptId: typeConceptId,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnitesEnregistrementDetailTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UnitesEnregistrementDetailTable,
        UniteEnregistrementDetailRow,
        $$UnitesEnregistrementDetailTableFilterComposer,
        $$UnitesEnregistrementDetailTableOrderingComposer,
        $$UnitesEnregistrementDetailTableAnnotationComposer,
        $$UnitesEnregistrementDetailTableCreateCompanionBuilder,
        $$UnitesEnregistrementDetailTableUpdateCompanionBuilder,
        (
          UniteEnregistrementDetailRow,
          BaseReferences<_$AppDatabase, $UnitesEnregistrementDetailTable,
              UniteEnregistrementDetailRow>
        ),
        UniteEnregistrementDetailRow,
        PrefetchHooks Function()>;
typedef $$SyncActionsTableCreateCompanionBuilder = SyncActionsCompanion
    Function({
  required String actionId,
  required int sequence,
  required String operation,
  required String entityType,
  Value<String?> localEntityId,
  Value<String?> serverEntityId,
  Value<String?> parentType,
  Value<String?> parentLocalId,
  Value<String?> parentServerId,
  required String payloadJson,
  Value<String?> blobRef,
  Value<int?> baseServerRevision,
  required String status,
  Value<String?> errorMessage,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncActionsTableUpdateCompanionBuilder = SyncActionsCompanion
    Function({
  Value<String> actionId,
  Value<int> sequence,
  Value<String> operation,
  Value<String> entityType,
  Value<String?> localEntityId,
  Value<String?> serverEntityId,
  Value<String?> parentType,
  Value<String?> parentLocalId,
  Value<String?> parentServerId,
  Value<String> payloadJson,
  Value<String?> blobRef,
  Value<int?> baseServerRevision,
  Value<String> status,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncActionsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncActionsTable> {
  $$SyncActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actionId => $composableBuilder(
      column: $table.actionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localEntityId => $composableBuilder(
      column: $table.localEntityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverEntityId => $composableBuilder(
      column: $table.serverEntityId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentLocalId => $composableBuilder(
      column: $table.parentLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentServerId => $composableBuilder(
      column: $table.parentServerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blobRef => $composableBuilder(
      column: $table.blobRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncActionsTable> {
  $$SyncActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actionId => $composableBuilder(
      column: $table.actionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localEntityId => $composableBuilder(
      column: $table.localEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverEntityId => $composableBuilder(
      column: $table.serverEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentLocalId => $composableBuilder(
      column: $table.parentLocalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentServerId => $composableBuilder(
      column: $table.parentServerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blobRef => $composableBuilder(
      column: $table.blobRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncActionsTable> {
  $$SyncActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get localEntityId => $composableBuilder(
      column: $table.localEntityId, builder: (column) => column);

  GeneratedColumn<String> get serverEntityId => $composableBuilder(
      column: $table.serverEntityId, builder: (column) => column);

  GeneratedColumn<String> get parentType => $composableBuilder(
      column: $table.parentType, builder: (column) => column);

  GeneratedColumn<String> get parentLocalId => $composableBuilder(
      column: $table.parentLocalId, builder: (column) => column);

  GeneratedColumn<String> get parentServerId => $composableBuilder(
      column: $table.parentServerId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get blobRef =>
      $composableBuilder(column: $table.blobRef, builder: (column) => column);

  GeneratedColumn<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncActionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncActionsTable,
    SyncActionRow,
    $$SyncActionsTableFilterComposer,
    $$SyncActionsTableOrderingComposer,
    $$SyncActionsTableAnnotationComposer,
    $$SyncActionsTableCreateCompanionBuilder,
    $$SyncActionsTableUpdateCompanionBuilder,
    (
      SyncActionRow,
      BaseReferences<_$AppDatabase, $SyncActionsTable, SyncActionRow>
    ),
    SyncActionRow,
    PrefetchHooks Function()> {
  $$SyncActionsTableTableManager(_$AppDatabase db, $SyncActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> actionId = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String?> localEntityId = const Value.absent(),
            Value<String?> serverEntityId = const Value.absent(),
            Value<String?> parentType = const Value.absent(),
            Value<String?> parentLocalId = const Value.absent(),
            Value<String?> parentServerId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String?> blobRef = const Value.absent(),
            Value<int?> baseServerRevision = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncActionsCompanion(
            actionId: actionId,
            sequence: sequence,
            operation: operation,
            entityType: entityType,
            localEntityId: localEntityId,
            serverEntityId: serverEntityId,
            parentType: parentType,
            parentLocalId: parentLocalId,
            parentServerId: parentServerId,
            payloadJson: payloadJson,
            blobRef: blobRef,
            baseServerRevision: baseServerRevision,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String actionId,
            required int sequence,
            required String operation,
            required String entityType,
            Value<String?> localEntityId = const Value.absent(),
            Value<String?> serverEntityId = const Value.absent(),
            Value<String?> parentType = const Value.absent(),
            Value<String?> parentLocalId = const Value.absent(),
            Value<String?> parentServerId = const Value.absent(),
            required String payloadJson,
            Value<String?> blobRef = const Value.absent(),
            Value<int?> baseServerRevision = const Value.absent(),
            required String status,
            Value<String?> errorMessage = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncActionsCompanion.insert(
            actionId: actionId,
            sequence: sequence,
            operation: operation,
            entityType: entityType,
            localEntityId: localEntityId,
            serverEntityId: serverEntityId,
            parentType: parentType,
            parentLocalId: parentLocalId,
            parentServerId: parentServerId,
            payloadJson: payloadJson,
            blobRef: blobRef,
            baseServerRevision: baseServerRevision,
            status: status,
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncActionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncActionsTable,
    SyncActionRow,
    $$SyncActionsTableFilterComposer,
    $$SyncActionsTableOrderingComposer,
    $$SyncActionsTableAnnotationComposer,
    $$SyncActionsTableCreateCompanionBuilder,
    $$SyncActionsTableUpdateCompanionBuilder,
    (
      SyncActionRow,
      BaseReferences<_$AppDatabase, $SyncActionsTable, SyncActionRow>
    ),
    SyncActionRow,
    PrefetchHooks Function()>;
typedef $$EntitySyncSnapshotsTableCreateCompanionBuilder
    = EntitySyncSnapshotsCompanion Function({
  required String entityType,
  required String entityId,
  Value<int> baseServerRevision,
  required String snapshotJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$EntitySyncSnapshotsTableUpdateCompanionBuilder
    = EntitySyncSnapshotsCompanion Function({
  Value<String> entityType,
  Value<String> entityId,
  Value<int> baseServerRevision,
  Value<String> snapshotJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EntitySyncSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $EntitySyncSnapshotsTable> {
  $$EntitySyncSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EntitySyncSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitySyncSnapshotsTable> {
  $$EntitySyncSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EntitySyncSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitySyncSnapshotsTable> {
  $$EntitySyncSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get baseServerRevision => $composableBuilder(
      column: $table.baseServerRevision, builder: (column) => column);

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
      column: $table.snapshotJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EntitySyncSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntitySyncSnapshotsTable,
    EntitySyncSnapshotRow,
    $$EntitySyncSnapshotsTableFilterComposer,
    $$EntitySyncSnapshotsTableOrderingComposer,
    $$EntitySyncSnapshotsTableAnnotationComposer,
    $$EntitySyncSnapshotsTableCreateCompanionBuilder,
    $$EntitySyncSnapshotsTableUpdateCompanionBuilder,
    (
      EntitySyncSnapshotRow,
      BaseReferences<_$AppDatabase, $EntitySyncSnapshotsTable,
          EntitySyncSnapshotRow>
    ),
    EntitySyncSnapshotRow,
    PrefetchHooks Function()> {
  $$EntitySyncSnapshotsTableTableManager(
      _$AppDatabase db, $EntitySyncSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitySyncSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitySyncSnapshotsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitySyncSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<int> baseServerRevision = const Value.absent(),
            Value<String> snapshotJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitySyncSnapshotsCompanion(
            entityType: entityType,
            entityId: entityId,
            baseServerRevision: baseServerRevision,
            snapshotJson: snapshotJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String entityId,
            Value<int> baseServerRevision = const Value.absent(),
            required String snapshotJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitySyncSnapshotsCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            baseServerRevision: baseServerRevision,
            snapshotJson: snapshotJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntitySyncSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntitySyncSnapshotsTable,
    EntitySyncSnapshotRow,
    $$EntitySyncSnapshotsTableFilterComposer,
    $$EntitySyncSnapshotsTableOrderingComposer,
    $$EntitySyncSnapshotsTableAnnotationComposer,
    $$EntitySyncSnapshotsTableCreateCompanionBuilder,
    $$EntitySyncSnapshotsTableUpdateCompanionBuilder,
    (
      EntitySyncSnapshotRow,
      BaseReferences<_$AppDatabase, $EntitySyncSnapshotsTable,
          EntitySyncSnapshotRow>
    ),
    EntitySyncSnapshotRow,
    PrefetchHooks Function()>;
typedef $$MobiliersTableCreateCompanionBuilder = MobiliersCompanion Function({
  required String resourceId,
  required String uniteEnregistrementId,
  required String displayCode,
  Value<String?> typeLabel,
  Value<DateTime?> collectionDate,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$MobiliersTableUpdateCompanionBuilder = MobiliersCompanion Function({
  Value<String> resourceId,
  Value<String> uniteEnregistrementId,
  Value<String> displayCode,
  Value<String?> typeLabel,
  Value<DateTime?> collectionDate,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$MobiliersTableFilterComposer
    extends Composer<_$AppDatabase, $MobiliersTable> {
  $$MobiliersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typeLabel => $composableBuilder(
      column: $table.typeLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get collectionDate => $composableBuilder(
      column: $table.collectionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$MobiliersTableOrderingComposer
    extends Composer<_$AppDatabase, $MobiliersTable> {
  $$MobiliersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typeLabel => $composableBuilder(
      column: $table.typeLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get collectionDate => $composableBuilder(
      column: $table.collectionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$MobiliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MobiliersTable> {
  $$MobiliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId, builder: (column) => column);

  GeneratedColumn<String> get displayCode => $composableBuilder(
      column: $table.displayCode, builder: (column) => column);

  GeneratedColumn<String> get typeLabel =>
      $composableBuilder(column: $table.typeLabel, builder: (column) => column);

  GeneratedColumn<DateTime> get collectionDate => $composableBuilder(
      column: $table.collectionDate, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MobiliersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MobiliersTable,
    MobilierCache,
    $$MobiliersTableFilterComposer,
    $$MobiliersTableOrderingComposer,
    $$MobiliersTableAnnotationComposer,
    $$MobiliersTableCreateCompanionBuilder,
    $$MobiliersTableUpdateCompanionBuilder,
    (
      MobilierCache,
      BaseReferences<_$AppDatabase, $MobiliersTable, MobilierCache>
    ),
    MobilierCache,
    PrefetchHooks Function()> {
  $$MobiliersTableTableManager(_$AppDatabase db, $MobiliersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MobiliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MobiliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MobiliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> uniteEnregistrementId = const Value.absent(),
            Value<String> displayCode = const Value.absent(),
            Value<String?> typeLabel = const Value.absent(),
            Value<DateTime?> collectionDate = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MobiliersCompanion(
            resourceId: resourceId,
            uniteEnregistrementId: uniteEnregistrementId,
            displayCode: displayCode,
            typeLabel: typeLabel,
            collectionDate: collectionDate,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String uniteEnregistrementId,
            required String displayCode,
            Value<String?> typeLabel = const Value.absent(),
            Value<DateTime?> collectionDate = const Value.absent(),
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MobiliersCompanion.insert(
            resourceId: resourceId,
            uniteEnregistrementId: uniteEnregistrementId,
            displayCode: displayCode,
            typeLabel: typeLabel,
            collectionDate: collectionDate,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MobiliersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MobiliersTable,
    MobilierCache,
    $$MobiliersTableFilterComposer,
    $$MobiliersTableOrderingComposer,
    $$MobiliersTableAnnotationComposer,
    $$MobiliersTableCreateCompanionBuilder,
    $$MobiliersTableUpdateCompanionBuilder,
    (
      MobilierCache,
      BaseReferences<_$AppDatabase, $MobiliersTable, MobilierCache>
    ),
    MobilierCache,
    PrefetchHooks Function()>;
typedef $$MobiliersDetailTableCreateCompanionBuilder = MobiliersDetailCompanion
    Function({
  required String resourceId,
  required String uniteEnregistrementId,
  required String fieldsJson,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$MobiliersDetailTableUpdateCompanionBuilder = MobiliersDetailCompanion
    Function({
  Value<String> resourceId,
  Value<String> uniteEnregistrementId,
  Value<String> fieldsJson,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$MobiliersDetailTableFilterComposer
    extends Composer<_$AppDatabase, $MobiliersDetailTable> {
  $$MobiliersDetailTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldsJson => $composableBuilder(
      column: $table.fieldsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$MobiliersDetailTableOrderingComposer
    extends Composer<_$AppDatabase, $MobiliersDetailTable> {
  $$MobiliersDetailTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldsJson => $composableBuilder(
      column: $table.fieldsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$MobiliersDetailTableAnnotationComposer
    extends Composer<_$AppDatabase, $MobiliersDetailTable> {
  $$MobiliersDetailTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get uniteEnregistrementId => $composableBuilder(
      column: $table.uniteEnregistrementId, builder: (column) => column);

  GeneratedColumn<String> get fieldsJson => $composableBuilder(
      column: $table.fieldsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MobiliersDetailTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MobiliersDetailTable,
    MobilierDetailRow,
    $$MobiliersDetailTableFilterComposer,
    $$MobiliersDetailTableOrderingComposer,
    $$MobiliersDetailTableAnnotationComposer,
    $$MobiliersDetailTableCreateCompanionBuilder,
    $$MobiliersDetailTableUpdateCompanionBuilder,
    (
      MobilierDetailRow,
      BaseReferences<_$AppDatabase, $MobiliersDetailTable, MobilierDetailRow>
    ),
    MobilierDetailRow,
    PrefetchHooks Function()> {
  $$MobiliersDetailTableTableManager(
      _$AppDatabase db, $MobiliersDetailTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MobiliersDetailTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MobiliersDetailTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MobiliersDetailTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resourceId = const Value.absent(),
            Value<String> uniteEnregistrementId = const Value.absent(),
            Value<String> fieldsJson = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MobiliersDetailCompanion(
            resourceId: resourceId,
            uniteEnregistrementId: uniteEnregistrementId,
            fieldsJson: fieldsJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resourceId,
            required String uniteEnregistrementId,
            required String fieldsJson,
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MobiliersDetailCompanion.insert(
            resourceId: resourceId,
            uniteEnregistrementId: uniteEnregistrementId,
            fieldsJson: fieldsJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MobiliersDetailTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MobiliersDetailTable,
    MobilierDetailRow,
    $$MobiliersDetailTableFilterComposer,
    $$MobiliersDetailTableOrderingComposer,
    $$MobiliersDetailTableAnnotationComposer,
    $$MobiliersDetailTableCreateCompanionBuilder,
    $$MobiliersDetailTableUpdateCompanionBuilder,
    (
      MobilierDetailRow,
      BaseReferences<_$AppDatabase, $MobiliersDetailTable, MobilierDetailRow>
    ),
    MobilierDetailRow,
    PrefetchHooks Function()>;
typedef $$ThesaurusSettingsTableCreateCompanionBuilder
    = ThesaurusSettingsCompanion Function({
  required int organisationId,
  required String scope,
  required String thesaurusUrl,
  Value<String?> thesaurusLabel,
  Value<bool> userConfigured,
  required DateTime updatedAt,
  Value<DateTime?> serverSyncedAt,
  Value<int> rowid,
});
typedef $$ThesaurusSettingsTableUpdateCompanionBuilder
    = ThesaurusSettingsCompanion Function({
  Value<int> organisationId,
  Value<String> scope,
  Value<String> thesaurusUrl,
  Value<String?> thesaurusLabel,
  Value<bool> userConfigured,
  Value<DateTime> updatedAt,
  Value<DateTime?> serverSyncedAt,
  Value<int> rowid,
});

final class $$ThesaurusSettingsTableReferences extends BaseReferences<
    _$AppDatabase, $ThesaurusSettingsTable, ThesaurusSettingRow> {
  $$ThesaurusSettingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $OrganisationsTable _organisationIdTable(_$AppDatabase db) =>
      db.organisations.createAlias($_aliasNameGenerator(
          db.thesaurusSettings.organisationId, db.organisations.id));

  $$OrganisationsTableProcessedTableManager get organisationId {
    final $_column = $_itemColumn<int>('organisation_id')!;

    final manager = $$OrganisationsTableTableManager($_db, $_db.organisations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_organisationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ThesaurusSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ThesaurusSettingsTable> {
  $$ThesaurusSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thesaurusUrl => $composableBuilder(
      column: $table.thesaurusUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thesaurusLabel => $composableBuilder(
      column: $table.thesaurusLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get userConfigured => $composableBuilder(
      column: $table.userConfigured,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get serverSyncedAt => $composableBuilder(
      column: $table.serverSyncedAt,
      builder: (column) => ColumnFilters(column));

  $$OrganisationsTableFilterComposer get organisationId {
    final $$OrganisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableFilterComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThesaurusSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThesaurusSettingsTable> {
  $$ThesaurusSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thesaurusUrl => $composableBuilder(
      column: $table.thesaurusUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thesaurusLabel => $composableBuilder(
      column: $table.thesaurusLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get userConfigured => $composableBuilder(
      column: $table.userConfigured,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get serverSyncedAt => $composableBuilder(
      column: $table.serverSyncedAt,
      builder: (column) => ColumnOrderings(column));

  $$OrganisationsTableOrderingComposer get organisationId {
    final $$OrganisationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableOrderingComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThesaurusSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThesaurusSettingsTable> {
  $$ThesaurusSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get thesaurusUrl => $composableBuilder(
      column: $table.thesaurusUrl, builder: (column) => column);

  GeneratedColumn<String> get thesaurusLabel => $composableBuilder(
      column: $table.thesaurusLabel, builder: (column) => column);

  GeneratedColumn<bool> get userConfigured => $composableBuilder(
      column: $table.userConfigured, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverSyncedAt => $composableBuilder(
      column: $table.serverSyncedAt, builder: (column) => column);

  $$OrganisationsTableAnnotationComposer get organisationId {
    final $$OrganisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ThesaurusSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ThesaurusSettingsTable,
    ThesaurusSettingRow,
    $$ThesaurusSettingsTableFilterComposer,
    $$ThesaurusSettingsTableOrderingComposer,
    $$ThesaurusSettingsTableAnnotationComposer,
    $$ThesaurusSettingsTableCreateCompanionBuilder,
    $$ThesaurusSettingsTableUpdateCompanionBuilder,
    (ThesaurusSettingRow, $$ThesaurusSettingsTableReferences),
    ThesaurusSettingRow,
    PrefetchHooks Function({bool organisationId})> {
  $$ThesaurusSettingsTableTableManager(
      _$AppDatabase db, $ThesaurusSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThesaurusSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThesaurusSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThesaurusSettingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> organisationId = const Value.absent(),
            Value<String> scope = const Value.absent(),
            Value<String> thesaurusUrl = const Value.absent(),
            Value<String?> thesaurusLabel = const Value.absent(),
            Value<bool> userConfigured = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> serverSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThesaurusSettingsCompanion(
            organisationId: organisationId,
            scope: scope,
            thesaurusUrl: thesaurusUrl,
            thesaurusLabel: thesaurusLabel,
            userConfigured: userConfigured,
            updatedAt: updatedAt,
            serverSyncedAt: serverSyncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int organisationId,
            required String scope,
            required String thesaurusUrl,
            Value<String?> thesaurusLabel = const Value.absent(),
            Value<bool> userConfigured = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime?> serverSyncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ThesaurusSettingsCompanion.insert(
            organisationId: organisationId,
            scope: scope,
            thesaurusUrl: thesaurusUrl,
            thesaurusLabel: thesaurusLabel,
            userConfigured: userConfigured,
            updatedAt: updatedAt,
            serverSyncedAt: serverSyncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ThesaurusSettingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({organisationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (organisationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.organisationId,
                    referencedTable: $$ThesaurusSettingsTableReferences
                        ._organisationIdTable(db),
                    referencedColumn: $$ThesaurusSettingsTableReferences
                        ._organisationIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ThesaurusSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ThesaurusSettingsTable,
    ThesaurusSettingRow,
    $$ThesaurusSettingsTableFilterComposer,
    $$ThesaurusSettingsTableOrderingComposer,
    $$ThesaurusSettingsTableAnnotationComposer,
    $$ThesaurusSettingsTableCreateCompanionBuilder,
    $$ThesaurusSettingsTableUpdateCompanionBuilder,
    (ThesaurusSettingRow, $$ThesaurusSettingsTableReferences),
    ThesaurusSettingRow,
    PrefetchHooks Function({bool organisationId})>;
typedef $$LieuxTableCreateCompanionBuilder = LieuxCompanion Function({
  required int placeId,
  required int organisationId,
  required String name,
  Value<String?> code,
  Value<bool> pendingSync,
  Value<bool> pendingDelete,
  Value<int?> typeConceptId,
  Value<String?> addressJson,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$LieuxTableUpdateCompanionBuilder = LieuxCompanion Function({
  Value<int> placeId,
  Value<int> organisationId,
  Value<String> name,
  Value<String?> code,
  Value<bool> pendingSync,
  Value<bool> pendingDelete,
  Value<int?> typeConceptId,
  Value<String?> addressJson,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

final class $$LieuxTableReferences
    extends BaseReferences<_$AppDatabase, $LieuxTable, LieuCache> {
  $$LieuxTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrganisationsTable _organisationIdTable(_$AppDatabase db) =>
      db.organisations.createAlias(
          $_aliasNameGenerator(db.lieux.organisationId, db.organisations.id));

  $$OrganisationsTableProcessedTableManager get organisationId {
    final $_column = $_itemColumn<int>('organisation_id')!;

    final manager = $$OrganisationsTableTableManager($_db, $_db.organisations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_organisationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LieuxTableFilterComposer extends Composer<_$AppDatabase, $LieuxTable> {
  $$LieuxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addressJson => $composableBuilder(
      column: $table.addressJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$OrganisationsTableFilterComposer get organisationId {
    final $$OrganisationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableFilterComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LieuxTableOrderingComposer
    extends Composer<_$AppDatabase, $LieuxTable> {
  $$LieuxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addressJson => $composableBuilder(
      column: $table.addressJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$OrganisationsTableOrderingComposer get organisationId {
    final $$OrganisationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableOrderingComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LieuxTableAnnotationComposer
    extends Composer<_$AppDatabase, $LieuxTable> {
  $$LieuxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete, builder: (column) => column);

  GeneratedColumn<int> get typeConceptId => $composableBuilder(
      column: $table.typeConceptId, builder: (column) => column);

  GeneratedColumn<String> get addressJson => $composableBuilder(
      column: $table.addressJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$OrganisationsTableAnnotationComposer get organisationId {
    final $$OrganisationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organisationId,
        referencedTable: $db.organisations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrganisationsTableAnnotationComposer(
              $db: $db,
              $table: $db.organisations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LieuxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LieuxTable,
    LieuCache,
    $$LieuxTableFilterComposer,
    $$LieuxTableOrderingComposer,
    $$LieuxTableAnnotationComposer,
    $$LieuxTableCreateCompanionBuilder,
    $$LieuxTableUpdateCompanionBuilder,
    (LieuCache, $$LieuxTableReferences),
    LieuCache,
    PrefetchHooks Function({bool organisationId})> {
  $$LieuxTableTableManager(_$AppDatabase db, $LieuxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LieuxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LieuxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LieuxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> placeId = const Value.absent(),
            Value<int> organisationId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> pendingDelete = const Value.absent(),
            Value<int?> typeConceptId = const Value.absent(),
            Value<String?> addressJson = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LieuxCompanion(
            placeId: placeId,
            organisationId: organisationId,
            name: name,
            code: code,
            pendingSync: pendingSync,
            pendingDelete: pendingDelete,
            typeConceptId: typeConceptId,
            addressJson: addressJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int placeId,
            required int organisationId,
            required String name,
            Value<String?> code = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> pendingDelete = const Value.absent(),
            Value<int?> typeConceptId = const Value.absent(),
            Value<String?> addressJson = const Value.absent(),
            required DateTime syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LieuxCompanion.insert(
            placeId: placeId,
            organisationId: organisationId,
            name: name,
            code: code,
            pendingSync: pendingSync,
            pendingDelete: pendingDelete,
            typeConceptId: typeConceptId,
            addressJson: addressJson,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$LieuxTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({organisationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (organisationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.organisationId,
                    referencedTable:
                        $$LieuxTableReferences._organisationIdTable(db),
                    referencedColumn:
                        $$LieuxTableReferences._organisationIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LieuxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LieuxTable,
    LieuCache,
    $$LieuxTableFilterComposer,
    $$LieuxTableOrderingComposer,
    $$LieuxTableAnnotationComposer,
    $$LieuxTableCreateCompanionBuilder,
    $$LieuxTableUpdateCompanionBuilder,
    (LieuCache, $$LieuxTableReferences),
    LieuCache,
    PrefetchHooks Function({bool organisationId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrganisationsTableTableManager get organisations =>
      $$OrganisationsTableTableManager(_db, _db.organisations);
  $$UtilisateursTableTableManager get utilisateurs =>
      $$UtilisateursTableTableManager(_db, _db.utilisateurs);
  $$FormsTableTableManager get forms =>
      $$FormsTableTableManager(_db, _db.forms);
  $$ProjetsTableTableManager get projets =>
      $$ProjetsTableTableManager(_db, _db.projets);
  $$ProjetsDetailTableTableManager get projetsDetail =>
      $$ProjetsDetailTableTableManager(_db, _db.projetsDetail);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DocumentsTmpTableTableManager get documentsTmp =>
      $$DocumentsTmpTableTableManager(_db, _db.documentsTmp);
  $$DocumentsUniteEnregistrementTableTableManager
      get documentsUniteEnregistrement =>
          $$DocumentsUniteEnregistrementTableTableManager(
              _db, _db.documentsUniteEnregistrement);
  $$UnitesEnregistrementTableTableManager get unitesEnregistrement =>
      $$UnitesEnregistrementTableTableManager(_db, _db.unitesEnregistrement);
  $$UnitesEnregistrementDetailTableTableManager
      get unitesEnregistrementDetail =>
          $$UnitesEnregistrementDetailTableTableManager(
              _db, _db.unitesEnregistrementDetail);
  $$SyncActionsTableTableManager get syncActions =>
      $$SyncActionsTableTableManager(_db, _db.syncActions);
  $$EntitySyncSnapshotsTableTableManager get entitySyncSnapshots =>
      $$EntitySyncSnapshotsTableTableManager(_db, _db.entitySyncSnapshots);
  $$MobiliersTableTableManager get mobiliers =>
      $$MobiliersTableTableManager(_db, _db.mobiliers);
  $$MobiliersDetailTableTableManager get mobiliersDetail =>
      $$MobiliersDetailTableTableManager(_db, _db.mobiliersDetail);
  $$ThesaurusSettingsTableTableManager get thesaurusSettings =>
      $$ThesaurusSettingsTableTableManager(_db, _db.thesaurusSettings);
  $$LieuxTableTableManager get lieux =>
      $$LieuxTableTableManager(_db, _db.lieux);
}
