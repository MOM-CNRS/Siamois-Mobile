import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/database/local_auth_store.dart';
import '../../core/database/tables.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/sync/sync_conflict_exception.dart';
import '../projects/form/person_option.dart';
import '../projects/form/project_form_models.dart';
import '../projects/form/spatial_unit_models.dart';
import '../projects/documents/document_form_models.dart';
import '../projects/documents/document_open_helper.dart';
import '../projects/documents/document_tmp_models.dart';
import '../projects/project_detail_models.dart';
import '../projects/recording_units/recording_unit_detail_models.dart';
import '../projects/recording_units/recording_unit_hierarchy.dart';
import '../projects/recording_units/recording_unit_relations_mapper.dart';
import '../projects/project_models.dart';
import '../projects/vocabulary_models.dart';
import 'auth_models.dart';
import 'credential_store.dart';
import 'token_helper.dart';

const _kPrefBaseUrl = 'siamois_auth_base_url';
const _kPrefAccessToken = 'siamois_auth_access_token';
const _kPrefExpiresAtMs = 'siamois_auth_expires_at_ms';
const _kPrefOrgId = 'siamois_auth_org_id';
const _kPrefOrgName = 'siamois_auth_org_name';
const _kPrefFirstName = 'siamois_auth_first_name';
const _kPrefLastName = 'siamois_auth_last_name';
const _kPrefEmail = 'siamois_auth_email';
const _kPrefPersonId = 'siamois_auth_person_id';

/// Auth JWT : `POST /api/v1/auth/login`, renouvellement silencieux uniquement
/// avant les appels API protégés (pas au démarrage ni pendant le login manuel).
class AuthRepository {
  AuthRepository({
    CredentialStore? credentialStore,
    AppDatabase? database,
    ConnectivityService? connectivity,
  })  : _credentials = credentialStore ?? CredentialStore(),
        _db = database,
        _connectivity = connectivity ?? ConnectivityService();

  final CredentialStore _credentials;
  final AppDatabase? _db;
  final ConnectivityService _connectivity;
  LocalAuthStore? _localAuth;
  Map<String, dynamic>? _lastLoginJson;

  static const _loginPath = '/api/v1/auth/login';

  late final Dio _dio;
  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  StoredAuthProfile? _profile;
  String _lastPersistedBaseUrl = '';
  Future<void>? _refreshInFlight;
  Future<bool>? _signInInFlight;

  /// Évite un second renouvellement juste après un login réussi.
  DateTime? _tokenObtainedAt;

  bool _initialized = false;
  bool _prefsRestored = false;

  StoredAuthProfile? get userProfile => _profile;

  /// Session ouverte sans jeton API (authentification locale uniquement).
  bool get isOfflineSession =>
      _profile != null && (_accessToken == null || _accessToken!.isEmpty);

  String get lastUsedBaseUrl =>
      _dio.options.baseUrl.trim().isNotEmpty
          ? _dio.options.baseUrl.trim()
          : _lastPersistedBaseUrl.trim();

  ConnectivityService get connectivity => _connectivity;

  Future<void> init() async {
    if (_initialized) return;
    if (_db != null) {
      _localAuth = LocalAuthStore(_db!);
    }
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isAuthEndpoint(options)) {
            handler.next(options);
            return;
          }
          try {
            await ensureValidAccessToken();
            final t = _accessToken;
            if (t != null && t.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $t';
            }
            handler.next(options);
          } on AuthException catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: e.message,
              ),
            );
          }
        },
        onError: (error, handler) async {
          final response = error.response;
          final opts = error.requestOptions;
          if (response?.statusCode == 401 &&
              !opts.extra.containsKey('authRetried') &&
              !_isAuthEndpoint(opts) &&
              !_isWithinFreshTokenGrace()) {
            try {
              await _renewAccessToken();
              opts.extra['authRetried'] = true;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final retry = await _dio.fetch<dynamic>(opts);
              handler.resolve(retry);
              return;
            } on AuthException {
              await _clearMemoryAndPrefs();
            }
          }
          handler.next(error);
        },
      ),
    );
    await _restoreFromPrefs();
    _initialized = true;
  }

  /// URL enregistrée par l’utilisateur (aucune URL « prod » implicite).
  String get configuredServerBaseUrl => lastUsedBaseUrl;

  Future<String> loadServerBaseUrl() async {
    if (!_initialized) await init();
    return configuredServerBaseUrl;
  }

  Future<void> setServerBaseUrl(String url) async {
    if (!_initialized) await init();
    final normalized = normalizeBaseUrl(url);
    if (normalized.isEmpty) {
      throw AuthException('URL du serveur invalide.');
    }
    if (!normalized.contains('://')) {
      throw AuthException(
        'URL invalide : utilisez http:// ou https://',
      );
    }
    _dio.options.baseUrl = normalized;
    _lastPersistedBaseUrl = normalized;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrefBaseUrl, normalized);
  }

  void _requireConfiguredServerBaseUrl() {
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw AuthException(
        'URL du serveur non configurée. Renseignez l’adresse API dans '
        'Paramètres serveur.',
      );
    }
  }

  bool _isWithinFreshTokenGrace() {
    final obtained = _tokenObtainedAt;
    if (obtained == null) return false;
    return DateTime.now().difference(obtained) < const Duration(seconds: 15);
  }

  bool _isAuthEndpoint(RequestOptions options) {
    if (options.extra['skipAuth'] == true) return true;
    final path = _requestPath(options);
    return path == _loginPath ||
        path == '$_loginPath/' ||
        path.endsWith(_loginPath) ||
        path.endsWith('$_loginPath/');
  }

  String _requestPath(RequestOptions options) {
    final uri = options.uri;
    if (uri.hasScheme) {
      var p = uri.path;
      if (p.isEmpty) p = '/';
      return p.split('?').first;
    }
    return options.path.split('?').first;
  }

  Future<void> ensureValidAccessToken() async {
    if (!_initialized) {
      throw StateError('AuthRepository.init() doit être appelé avant les appels API.');
    }
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw AuthException('URL du serveur inconnue. Reconnectez-vous.');
    }
    if ((_accessToken ?? '').trim().isEmpty) {
      final restored = await _tryRestoreAccessToken();
      if (!restored) {
        if (isOfflineSession) {
          throw AuthException(
            'Session hors ligne sans accès API. '
            'Connectez-vous en ligne pour enregistrer sur le serveur.',
          );
        }
        throw AuthException(
          'Session expirée. Reconnectez-vous avec votre e-mail et mot de passe.',
        );
      }
    }
    if (_isWithinFreshTokenGrace()) {
      return;
    }
    if (!tokenNeedsRefresh(
      accessToken: _accessToken,
      expiresAt: _accessTokenExpiresAt,
    )) {
      return;
    }
    await _renewAccessToken();
  }

  Future<void> _renewAccessToken() {
    _refreshInFlight ??= _doRenewAccessToken().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<void> _doRenewAccessToken() async {
    if (kDebugMode) {
      debugPrint('[Siamois] Renouvellement du jeton (login silencieux)…');
    }

    final creds = await _credentials.read();
    final email = creds.email;
    final password = creds.password;
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      await _clearMemoryAndPrefs();
      throw AuthException(
        'Session expirée. Reconnectez-vous avec votre e-mail et mot de passe.',
      );
    }

    await _loginRequest(email: email, password: password, silent: true);
  }

  Future<void> _restoreFromPrefs() async {
    if (_prefsRestored) return;
    _prefsRestored = true;

    final p = await SharedPreferences.getInstance();
    final rawPersisted = p.getString(_kPrefBaseUrl) ?? '';
    _lastPersistedBaseUrl = _resolvePersistedBaseUrl(rawPersisted);
    if (_lastPersistedBaseUrl.isNotEmpty) {
      _dio.options.baseUrl = _lastPersistedBaseUrl;
      if (_lastPersistedBaseUrl != normalizeBaseUrl(rawPersisted)) {
        await p.setString(_kPrefBaseUrl, _lastPersistedBaseUrl);
      }
    }
    _accessToken = p.getString(_kPrefAccessToken);
    if ((_accessToken ?? '').isEmpty) _accessToken = null;
    final expMs = p.getInt(_kPrefExpiresAtMs);
    _accessTokenExpiresAt =
        expMs != null ? DateTime.fromMillisecondsSinceEpoch(expMs) : null;

    final oid = p.getInt(_kPrefOrgId);
    final on = p.getString(_kPrefOrgName);
    final fn = p.getString(_kPrefFirstName) ?? '';
    final ln = p.getString(_kPrefLastName) ?? '';
    final em = p.getString(_kPrefEmail) ?? '';
    final personId = p.getInt(_kPrefPersonId);
    if (em.isNotEmpty || fn.isNotEmpty || ln.isNotEmpty) {
      _profile = StoredAuthProfile(
        email: em,
        firstName: fn,
        lastName: ln,
        personId: personId,
        primaryOrganizationId: oid,
        primaryOrganizationName: (on == null || on.isEmpty) ? null : on,
      );
    } else {
      _profile = null;
    }

  }

  /// Tente un login silencieux si le serveur est joignable (jeton absent ou expiré).
  Future<bool> _tryRestoreAccessToken() async {
    if (!await isServerReachable()) return false;

    var email = _profile?.email.trim() ?? '';
    var password = '';

    final creds = await _credentials.read();
    if (creds.email != null && creds.email!.trim().isNotEmpty) {
      email = creds.email!.trim();
    }
    if (creds.password != null && creds.password!.isNotEmpty) {
      password = creds.password!;
    }

    if (password.isEmpty && email.isNotEmpty) {
      final store = _localAuth;
      if (store != null) {
        password = await store.storedPasswordForEmail(email) ?? '';
      }
    }

    if (email.isEmpty || password.isEmpty) return false;

    try {
      await _loginRequest(email: email, password: password, silent: true);
      return (_accessToken ?? '').trim().isNotEmpty;
    } on AuthException {
      return false;
    }
  }

  /// Reprend la session API (renouvelle le jeton si besoin).
  Future<bool> resumeSessionIfValid() async {
    if (!_initialized) await init();
    if (_dio.options.baseUrl.trim().isEmpty) return false;

    if ((_accessToken ?? '').trim().isEmpty) {
      return _tryRestoreAccessToken();
    }

    if (tokenNeedsRefresh(
      accessToken: _accessToken,
      expiresAt: _accessTokenExpiresAt,
    )) {
      try {
        await _renewAccessToken();
      } on AuthException {
        return _tryRestoreAccessToken();
      }
    }
    return true;
  }

  /// Reprend une session hors ligne à partir de la base locale (sans jeton API).
  Future<bool> resumeLocalSessionIfPossible() async {
    if (!_initialized) await init();
    final store = _localAuth;
    if (store == null) return false;

    var email = _profile?.email.trim() ?? '';
    if (email.isEmpty) {
      final p = await SharedPreferences.getInstance();
      email = p.getString(_kPrefEmail)?.trim() ?? '';
    }
    if (email.isEmpty) return false;

    final profile = await store.profileFromLocalDb(email);
    if (profile == null) return false;

    _profile = profile;
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _tokenObtainedAt = null;

    final p = await SharedPreferences.getInstance();
    await p.remove(_kPrefAccessToken);
    await p.remove(_kPrefExpiresAtMs);
    await _persistToPrefs();

    if (kDebugMode) {
      debugPrint('[Siamois] Session locale reprise pour ${profile.email}');
    }
    return true;
  }

  Future<void> _persistToPrefs() async {
    final p = await SharedPreferences.getInstance();
    final base = _dio.options.baseUrl.trim();
    await p.setString(_kPrefBaseUrl, base);
    _lastPersistedBaseUrl = base;
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      await p.setString(_kPrefAccessToken, _accessToken!);
    } else {
      await p.remove(_kPrefAccessToken);
    }
    if (_accessTokenExpiresAt != null) {
      await p.setInt(
        _kPrefExpiresAtMs,
        _accessTokenExpiresAt!.millisecondsSinceEpoch,
      );
    } else {
      await p.remove(_kPrefExpiresAtMs);
    }
    final pr = _profile;
    if (pr != null) {
      await p.setString(_kPrefEmail, pr.email);
      await p.setString(_kPrefFirstName, pr.firstName);
      await p.setString(_kPrefLastName, pr.lastName);
      final pid = pr.personId;
      if (pid != null) {
        await p.setInt(_kPrefPersonId, pid);
      } else {
        await p.remove(_kPrefPersonId);
      }
      final oid = pr.primaryOrganizationId;
      if (oid != null) {
        await p.setInt(_kPrefOrgId, oid);
      } else {
        await p.remove(_kPrefOrgId);
      }
      final on = pr.primaryOrganizationName ?? '';
      if (on.isNotEmpty) {
        await p.setString(_kPrefOrgName, on);
      } else {
        await p.remove(_kPrefOrgName);
      }
    }
  }

  Future<void> _clearMemoryAndPrefs() async {
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _tokenObtainedAt = null;
    _profile = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPrefAccessToken);
    await p.remove(_kPrefExpiresAtMs);
    await p.remove(_kPrefOrgId);
    await p.remove(_kPrefOrgName);
    await p.remove(_kPrefFirstName);
    await p.remove(_kPrefLastName);
    await p.remove(_kPrefEmail);
    await p.remove(_kPrefPersonId);
    await _credentials.clear();
  }

  static String normalizeBaseUrl(String input) {
    var s = input.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    const swaggerSuffix = '/swagger-ui/index.html';
    if (s.endsWith(swaggerSuffix)) {
      s = s.substring(0, s.length - swaggerSuffix.length);
      while (s.endsWith('/')) {
        s = s.substring(0, s.length - 1);
      }
    }
    return s;
  }

  static String _resolvePersistedBaseUrl(String? persisted) {
    return normalizeBaseUrl(persisted ?? '');
  }

  /// `true` si connexion API, `false` si authentification locale hors ligne.
  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    final inFlight = _signInInFlight;
    if (inFlight != null) return inFlight;
    final future = _performSignIn(
      email: email,
      password: password,
    );
    _signInInFlight = future;
    return future.whenComplete(() {
      if (identical(_signInInFlight, future)) {
        _signInInFlight = null;
      }
    });
  }

  Future<bool> _performSignIn({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      throw StateError('AuthRepository.init() doit être appelé avant signIn');
    }

    _requireConfiguredServerBaseUrl();
    final normalized = _dio.options.baseUrl.trim();

    _refreshInFlight = null;

    final online = await _connectivity.isOnline(normalized);
    if (online) {
      await _loginRequest(
        email: email.trim(),
        password: password,
        silent: false,
      );
      await _credentials.save(email.trim(), password);
      await _persistLoginToLocalDb(
        email: email.trim(),
        password: password,
      );
      return true;
    }

    return _signInOffline(email: email.trim(), password: password);
  }

  Future<bool> _signInOffline({
    required String email,
    required String password,
  }) async {
    final store = _localAuth;
    if (store == null) {
      throw AuthException(
        'Mode hors ligne indisponible (base locale non initialisée).',
      );
    }

    final profile = await store.authenticateOffline(
      email: email,
      password: password,
    );
    if (profile == null) {
      throw AuthException(
        'Identifiants incorrects ou aucune donnée locale. '
        'Connectez-vous une première fois en ligne.',
      );
    }

    _profile = profile;
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _tokenObtainedAt = null;

    final p = await SharedPreferences.getInstance();
    await p.remove(_kPrefAccessToken);
    await p.remove(_kPrefExpiresAtMs);
    await _persistToPrefs();

    if (kDebugMode) {
      debugPrint('[Siamois] Connexion hors ligne pour ${profile.email}');
    }
    return false;
  }

  Future<void> _persistLoginToLocalDb({
    required String email,
    required String password,
  }) async {
    final json = _lastLoginJson;
    final store = _localAuth;
    if (json == null || store == null) return;
    await store.saveFromLoginResponse(
      loginJson: json,
      email: email,
      password: password,
    );
  }

  Future<void> _loginRequest({
    required String email,
    required String password,
    bool silent = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _loginPath,
        data: {'email': email, 'password': password},
        options: Options(
          extra: const {'skipAuth': true},
          headers: {
            Headers.acceptHeader: 'application/json',
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
          validateStatus: (c) => c != null && c < 600,
        ),
      );

      final code = response.statusCode ?? 0;
      final json = _coerceMap(response.data);

      if (code == 401 || code == 403) {
        throw AuthException(
          _msgFromJson(json) ?? 'Identifiants incorrects ou accès refusé.',
        );
      }
      if (code != 200 || json == null) {
        throw AuthException(
          _msgFromJson(json) ?? 'Erreur de connexion (code $code).',
        );
      }

      _lastLoginJson = json;
      _applyLoginJson(json, fallbackEmail: email);
      _tokenObtainedAt = DateTime.now();
      await _persistToPrefs();

      if (kDebugMode && !silent) {
        debugPrint(
          '[Siamois] Connexion OK — jeton valide jusqu’à ~$_accessTokenExpiresAt',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      final json = _coerceMap(e.response?.data);
      final status = e.response?.statusCode ?? 0;
      throw AuthException(
        _msgFromJson(json) ??
            (status == 401 || status == 403
                ? 'Identifiants incorrects ou accès refusé.'
                : e.message ?? 'Erreur réseau à la connexion.'),
      );
    }
  }

  void _applyLoginJson(
    Map<String, dynamic> json, {
    required String fallbackEmail,
  }) {
    final token = json['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw AuthException(
        'Réponse sans accessToken. Vérifiez l’URL du serveur.',
      );
    }
    _accessToken = token.trim();

    final expiresIn = json['expiresIn'];
    if (expiresIn is int && expiresIn > 0) {
      _accessTokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    } else if (expiresIn is num) {
      final s = expiresIn.toInt();
      if (s > 0) {
        _accessTokenExpiresAt = DateTime.now().add(Duration(seconds: s));
      }
    } else {
      _accessTokenExpiresAt = jwtExpirationUtc(_accessToken!);
    }

    var profile =
        StoredAuthProfile.fromLoginJson(json) ??
        StoredAuthProfile(
          email: fallbackEmail,
          firstName: '',
          lastName: '',
        );
    if (profile.personId == null) {
      final fromToken = _personIdFromAccessToken(_accessToken!);
      if (fromToken != null) {
        profile = StoredAuthProfile(
          email: profile.email,
          firstName: profile.firstName,
          lastName: profile.lastName,
          username: profile.username,
          personId: fromToken,
          primaryOrganizationId: profile.primaryOrganizationId,
          primaryOrganizationName: profile.primaryOrganizationName,
          organizations: profile.organizations,
        );
      }
    }
    _profile = profile;
  }

  int? _personIdFromAccessToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      final candidates = [map['sub'], map['personId'], map['id']];
      for (final raw in candidates) {
        final id = _parseInt(raw);
        if (id != null) return id;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearSession() async {
    await _clearMemoryAndPrefs();
    _prefsRestored = false;
  }

  int? get primaryOrganizationId => _profile?.primaryOrganizationId;

  Future<bool> isServerReachable() async {
    final base = _dio.options.baseUrl.trim();
    if (base.isEmpty) return false;
    return _connectivity.isOnline(base);
  }

  /// Réseau joignable et session API active (pas le mode hors ligne local).
  Future<bool> canUseProjectsApi() async {
    if (isOfflineSession) return false;
    if ((_accessToken ?? '').trim().isEmpty) return false;
    return isServerReachable();
  }

  /// Serveur injoignable (réseau ou API) — pour les bandeaux « hors ligne ».
  ///
  /// Ne pas confondre avec [canUseProjectsApi] : une session locale sans jeton
  /// peut afficher « connecté » si le serveur répond.
  Future<bool> isOfflineEnvironment() async => !(await isServerReachable());

  Future<Map<String, dynamic>> fetchVocabulariesRaw({
    required int organizationId,
  }) async {
    final body = await _getJson(
      '/api/v1/vocabularies',
      queryParameters: {'organizationId': organizationId.toString()},
    );
    return body ?? {};
  }

  /// URL du thésaurus configurée pour l’utilisateur (`GET /api/v1/users/me/thesaurus`).
  ///
  /// Retourne [null] si l’endpoint est absent, inaccessible ou sans configuration.
  Future<String?> fetchUserThesaurusUrl({
    required int organizationId,
  }) async {
    final body = await _getJsonOptional(
      '/api/v1/users/me/thesaurus',
      queryParameters: {'organizationId': organizationId.toString()},
    );
    if (body == null) return null;
    return _readThesaurusUrlFromResponse(body);
  }

  /// Applique la configuration thésaurus côté serveur (import des concepts).
  Future<void> saveUserThesaurusConfig({
    required int organizationId,
    required String thesaurusUrl,
    void Function(int sent, int total)? onUploadProgress,
  }) async {
    _ensureReadyForProjectsApi();
    final response = await _putThesaurusJson(
      '/api/v1/users/me/thesaurus',
      data: {
        'organizationId': organizationId,
        'thesaurusUrl': thesaurusUrl.trim(),
      },
      onSendProgress: onUploadProgress,
    );
    _ensureThesaurusConfigSaved(response);
  }

  String? _readThesaurusUrlFromResponse(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map) {
      final url = data['thesaurusUrl'] ?? data['url'];
      if (url != null) {
        final s = url.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    final direct = body['thesaurusUrl'] ?? body['url'];
    if (direct != null) {
      final s = direct.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchProjectFormRaw({
    required int organizationId,
  }) async {
    final body = await _getJson(
      '/api/v1/projects/form',
      queryParameters: {'organizationId': organizationId.toString()},
    );
    return body ?? {};
  }

  Future<Map<String, dynamic>> fetchMobilierFormRaw({
    required int organizationId,
    String? mobilierId,
  }) async {
    _ensureReadyForProjectsApi();
    if (mobilierId != null && mobilierId.trim().isNotEmpty) {
      final encoded = Uri.encodeComponent(mobilierId.trim());
      final body = await _getJson('/api/v1/finds/$encoded');
      return body ?? {};
    }
    final body = await _getJson(
      '/api/v1/finds/form',
      queryParameters: {'organizationId': organizationId.toString()},
    );
    return body ?? {};
  }

  Future<MobilierItem> createMobilier({
    required String recordingUnitId,
    required int specimenTypeConceptId,
    Map<String, dynamic> fieldAnswers = const {},
  }) async {
    _ensureReadyForProjectsApi();
    final response = await _postJson(
      '/api/v1/finds',
      data: {
        'recordingUnitId': recordingUnitId.trim(),
        'specimenTypeConceptId': specimenTypeConceptId.toString(),
        if (fieldAnswers.isNotEmpty) 'fieldAnswers': fieldAnswers,
      },
    );

    final code = response.statusCode ?? 0;
    if (code == 201) {
      final item = response.data?['data'];
      if (item is Map<String, dynamic>) {
        return MobilierItem.fromJson(item);
      }
      if (item is Map) {
        return MobilierItem.fromJson(Map<String, dynamic>.from(item));
      }
      throw AuthException('Réponse serveur inattendue après création.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de créer le mobilier (code $code).',
    );
  }

  Future<MobilierItem> patchMobilier({
    required String findId,
    Map<String, dynamic> fieldAnswers = const {},
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(findId.trim());
    final response = await _patchJson(
      '/api/v1/finds/$encoded',
      data: {'fieldAnswers': fieldAnswers},
    );

    final code = response.statusCode ?? 0;
    if (code == 200) {
      final item = response.data?['data'];
      if (item is Map<String, dynamic>) {
        return MobilierItem.fromJson(item);
      }
      if (item is Map) {
        return MobilierItem.fromJson(Map<String, dynamic>.from(item));
      }
      throw AuthException('Réponse serveur inattendue après modification.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de modifier le mobilier (code $code).',
    );
  }

  Future<void> deleteMobilier(String findId) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(findId.trim());
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/finds/$encoded',
      options: Options(
        headers: {Headers.acceptHeader: 'application/json'},
        validateStatus: (c) => c != null && c < 600,
      ),
    );
    final code = response.statusCode ?? 0;
    if (code == 204 || code == 200) return;

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de supprimer le mobilier (code $code).',
    );
  }

  Future<Map<String, dynamic>> fetchDocumentFormRaw({
    required int organizationId,
    String? documentId,
  }) async {
    _ensureReadyForProjectsApi();
    final params = <String, String>{
      'organizationId': organizationId.toString(),
    };
    final docId = documentId?.trim();
    if (docId != null && docId.isNotEmpty) {
      params['documentId'] = docId;
    }
    final body = await _getJson(
      '/api/v1/documents/form',
      queryParameters: params,
    );
    return body ?? {};
  }

  Future<ProjectDocumentItem> createRecordingUnitDocument({
    required String recordingUnitId,
    required String title,
    String? description,
    int? natureConceptId,
    int? scaleConceptId,
    int? formatConceptId,
    required String filePath,
    required String fileName,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final formData = FormData.fromMap({
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (natureConceptId != null) 'natureConceptId': natureConceptId,
      if (scaleConceptId != null) 'scaleConceptId': scaleConceptId,
      if (formatConceptId != null) 'formatConceptId': formatConceptId,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base/api/v1/recording-units/$encoded/documents');

    if (kDebugMode) {
      debugPrint('[Siamois] POST (multipart) $uri');
    }

    try {
      final response = await _dio.postUri<Map<String, dynamic>>(
        uri,
        data: formData,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 201 || code == 200) {
        final data = response.data?['data'];
        if (data is Map) {
          return ProjectDocumentItem.fromJson(Map<String, dynamic>.from(data));
        }
        throw AuthException('Réponse document invalide après création.');
      }
      throw _authExceptionFromResponse(
        response,
        fallback: 'Impossible de créer le document (code $code).',
      );
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'création du document');
    }
  }

  Future<ProjectDocumentItem> createProjectDocument({
    required String projectId,
    required String title,
    String? description,
    int? natureConceptId,
    int? scaleConceptId,
    int? formatConceptId,
    required String filePath,
    required String fileName,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(projectId.trim());
    final formData = FormData.fromMap({
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (natureConceptId != null) 'natureConceptId': natureConceptId,
      if (scaleConceptId != null) 'scaleConceptId': scaleConceptId,
      if (formatConceptId != null) 'formatConceptId': formatConceptId,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base/api/v1/projects/$encoded/documents');

    if (kDebugMode) {
      debugPrint('[Siamois] POST (multipart) $uri');
    }

    try {
      final response = await _dio.postUri<Map<String, dynamic>>(
        uri,
        data: formData,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 201 || code == 200) {
        final data = response.data?['data'];
        if (data is Map) {
          return ProjectDocumentItem.fromJson(Map<String, dynamic>.from(data));
        }
        throw AuthException('Réponse document invalide après création.');
      }
      throw _authExceptionFromResponse(
        response,
        fallback: 'Impossible de créer le document (code $code).',
      );
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'création du document');
    }
  }

  /// Met à jour les métadonnées d’un document (`PATCH /api/v1/documents/{id}`).
  ///
  /// [documentId] : identifiant numérique serveur (`resourceId` dans les listes).
  Future<ProjectDocumentItem> patchDocument({
    required String documentId,
    required DocumentPatchPayload payload,
  }) async {
    _ensureReadyForProjectsApi();
    final id = documentId.trim();
    if (id.isEmpty) {
      throw AuthException('Identifiant de document invalide.');
    }
    if (DocumentTmpEntry.isLocalListId(id)) {
      throw AuthException(
        'Ce document n’est pas encore sur le serveur. '
        'Synchronisez-le avant de le modifier.',
      );
    }

    final encoded = Uri.encodeComponent(id);
    final response = await _patchJson(
      '/api/v1/documents/$encoded',
      data: payload.toJson(),
    );
    final code = response.statusCode ?? 0;
    if (code == 200) {
      final body = response.data;
      final data = body?['data'];
      if (data is Map) {
        return ProjectDocumentItem.fromJson(Map<String, dynamic>.from(data));
      }
      throw AuthException('Réponse document invalide après modification.');
    }
    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de modifier le document (code $code).',
    );
  }

  /// Construit une URL absolue à partir d’un chemin relatif API (`url`).
  String? absoluteServerUrl(String? relativePath) {
    final base = _dio.options.baseUrl.trim();
    if (base.isEmpty) return null;

    final rel = relativePath?.trim();
    if (rel == null || rel.isEmpty) return null;
    if (rel.startsWith('http://') || rel.startsWith('https://')) return rel;

    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedRel = rel.startsWith('/') ? rel : '/$rel';
    return '$normalizedBase$normalizedRel';
  }

  /// Télécharge le binaire d’un document (`GET /api/v1/documents/{id}`).
  Future<Uint8List> downloadDocumentBytes({
    required String resourceId,
  }) async {
    _ensureReadyForProjectsApi();
    final id = resourceId.trim();
    if (id.isEmpty) {
      throw AuthException('Identifiant de document invalide.');
    }

    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base/api/v1/documents/$id');

    if (kDebugMode) {
      debugPrint('[Siamois] GET (binary) $uri');
    }

    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {Headers.acceptHeader: '*/*'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 401) {
        throw AuthException('Session expirée. Reconnectez-vous.');
      }
      if (code == 404) {
        throw AuthException('Document ou fichier introuvable.');
      }
      if (code != 200) {
        throw AuthException(
          'Impossible de télécharger le document (code $code).',
        );
      }

      final bytes = _bytesFromResponse(response.data);
      if (bytes.isEmpty) {
        throw AuthException('Fichier document vide.');
      }
      if (DocumentOpenHelper.looksLikeErrorPayload(bytes)) {
        throw AuthException(
          'Le serveur n’a pas renvoyé un fichier (réponse HTML/JSON). '
          'Vérifiez vos droits ou reconnectez-vous.',
        );
      }
      return bytes;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'téléchargement du document');
    }
  }

  /// Télécharge le fichier via `GET /api/v1/documents/{resourceId}` (authentifié).
  Future<File> downloadDocumentToTempFile({
    required String resourceId,
    required String suggestedFileName,
    String? mimeType,
  }) async {
    final bytes = await downloadDocumentBytes(resourceId: resourceId);
    final safeName = DocumentOpenHelper.sanitizeFileName(
      suggestedFileName,
      mimeType: mimeType,
    );

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, safeName));
    await file.writeAsBytes(bytes, flush: true);

    if (kDebugMode) {
      debugPrint(
        '[Siamois] Document enregistré : ${file.path} '
        '(${bytes.length} octets, type: ${mimeType ?? '?'})',
      );
    }

    return file;
  }

  static Uint8List _bytesFromResponse(dynamic data) {
    if (data == null) return Uint8List(0);
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw AuthException('Réponse binaire invalide du serveur.');
  }

  Future<void> deleteDocument(String documentId) async {
    _ensureReadyForProjectsApi();
    final id = documentId.trim();
    if (id.isEmpty) {
      throw AuthException('Identifiant de document invalide.');
    }

    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base/api/v1/documents/$id');

    if (kDebugMode) {
      debugPrint('[Siamois] DELETE $uri');
    }

    try {
      final response = await _dio.deleteUri<Map<String, dynamic>>(
        uri,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 204 || code == 200) return;
      throw _authExceptionFromResponse(
        response,
        fallback: 'Impossible de supprimer le document (code $code).',
      );
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'suppression du document');
    }
  }

  Future<Map<String, dynamic>> fetchProjectDetail(String projectId) async {
    _ensureReadyForProjectsApi();
    final key = projectId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant de projet invalide.');
    }

    final encoded = Uri.encodeComponent(key);
    final body = await _getJson('/api/v1/projects/$encoded');
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw AuthException('Réponse projet invalide.');
  }

  Future<List<ProjectDocumentItem>> fetchProjectDocuments(
    String projectId,
  ) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(projectId.trim());
    final body = await _getJson('/api/v1/projects/$encoded/documents');
    final data = body?['data'];
    if (data is! Map) return const [];

    final docs = data['documents'];
    if (docs is! List) return const [];

    return docs
        .whereType<Map>()
        .map((e) => ProjectDocumentItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<RecordingUnitListResult> fetchProjectRecordingUnits(
    String projectId, {
    int offset = 0,
    int limit = 20,
    String sort = 'creationTime:desc',
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(projectId.trim());
    final body = await _getJson(
      '/api/v1/projects/$encoded/recording-units',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sort,
      },
    );

    final rawList = body?['data'];
    final items = <RecordingUnitItem>[];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is Map) {
          items.add(
            RecordingUnitItem.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final meta = body?['meta'];
    int total = items.length;
    int parsedOffset = offset;
    int parsedLimit = limit;
    if (meta is Map) {
      total = _parseInt(meta['total']) ?? total;
      parsedOffset = _parseInt(meta['offset']) ?? offset;
      parsedLimit = _parseInt(meta['limit']) ?? limit;
    }

    return RecordingUnitListResult(
      items: items,
      total: total,
      offset: parsedOffset,
      limit: parsedLimit,
    );
  }

  Future<List<ConceptOption>> fetchRecordingUnitTypeConcepts() async {
    final orgId = primaryOrganizationId;
    if (orgId == null) {
      throw AuthException(
        'Organisation inconnue. Reconnectez-vous.',
      );
    }

    final db = _db;
    if (db != null) {
      for (final loader in [
        () => db.findValidForm(
              organisationId: orgId,
              type: FormCacheType.vocabulaire,
            ),
        () => db.findLatestForm(
              organisationId: orgId,
              type: FormCacheType.vocabulaire,
            ),
      ]) {
        final row = await loader();
        final types = _recordingUnitTypesFromVocabRow(row);
        if (types != null && types.isNotEmpty) return types;
      }
    }

    if (!await canUseProjectsApi()) {
      throw AuthException(
        'Types d’UE indisponibles hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }

    _ensureReadyForProjectsApi();
    final body = await fetchVocabulariesRaw(organizationId: orgId);
    final data = body['data'];
    if (data is! Map) return const [];

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const [];

    return ConceptOption.recordingUnitTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  List<ConceptOption>? _projectTypesFromVocabRow(Form? row) {
    if (row == null) return null;
    final db = _db;
    if (db == null) return null;
    final map = db.decodeFormMap(row);
    final data = map?['data'];
    if (data is! Map) return null;
    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return null;
    return ConceptOption.projectTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  List<ConceptOption>? _recordingUnitTypesFromVocabRow(Form? row) {
    if (row == null) return null;
    final db = _db;
    if (db == null) return null;
    final map = db.decodeFormMap(row);
    final data = map?['data'];
    if (data is! Map) return null;
    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return null;
    return ConceptOption.recordingUnitTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  Future<Map<String, dynamic>> fetchRecordingUnitCreationFormRaw({
    required int organizationId,
    required int recordingUnitTypeConceptId,
  }) async {
    _ensureReadyForProjectsApi();
    final body = await _getJson(
      '/api/v1/recording-units/creation-form',
      queryParameters: {
        'organizationId': organizationId.toString(),
        'recordingUnitTypeConceptId': recordingUnitTypeConceptId.toString(),
      },
    );
    return body ?? {};
  }

  Future<RecordingUnitMobileDetail> createRecordingUnit({
    required String actionUnitId,
    required int recordingUnitTypeConceptId,
    Map<String, dynamic> fieldAnswers = const {},
  }) async {
    _ensureReadyForProjectsApi();
    final response = await _postJson(
      '/api/v1/recording-units',
      data: {
        'actionUnitId': actionUnitId.trim(),
        'recordingUnitTypeConceptId': recordingUnitTypeConceptId,
        if (fieldAnswers.isNotEmpty) 'fieldAnswers': fieldAnswers,
      },
    );

    final code = response.statusCode ?? 0;
    if (code == 201) {
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return RecordingUnitMobileDetail.fromApiData(data);
      }
      if (data is Map) {
        return RecordingUnitMobileDetail.fromApiData(
          Map<String, dynamic>.from(data),
        );
      }
      throw AuthException('Réponse serveur inattendue après création UE.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de créer l’unité d’enregistrement (code $code).',
    );
  }

  Future<RecordingUnitMobileDetail> patchRecordingUnit(
    String recordingUnitId, {
    Map<String, dynamic> fieldAnswers = const {},
    int? expectedRevision,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final body = <String, dynamic>{
      'fieldAnswers': fieldAnswers,
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
    };
    final response = await _patchJson(
      '/api/v1/recording-units/$encoded',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code == 200) {
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return RecordingUnitMobileDetail.fromApiData(data);
      }
      if (data is Map) {
        return RecordingUnitMobileDetail.fromApiData(
          Map<String, dynamic>.from(data),
        );
      }
      throw AuthException('Réponse serveur inattendue après modification UE.');
    }

    if (code == 409) {
      throw _syncConflictFromResponse(response, recordingUnitId);
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de modifier l’unité d’enregistrement (code $code).',
    );
  }

  SyncConflictException _syncConflictFromResponse(
    Response<Map<String, dynamic>> response,
    String entityId,
  ) {
    final root = response.data;
    final data = root?['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final serverState = map['serverState'];
      RecordingUnitMobileDetail? detail;
      if (serverState is Map) {
        detail = RecordingUnitMobileDetail.fromApiData(
          Map<String, dynamic>.from(serverState),
        );
      }
      return SyncConflictException(
        entityType: map['entityType']?.toString() ?? 'recording_unit',
        entityId: map['entityId']?.toString() ?? entityId,
        expectedRevision: _intFrom(map['expectedRevision']),
        currentRevision: _intFrom(map['currentRevision']),
        serverDetail: detail,
      );
    }
    return SyncConflictException(
      entityType: 'recording_unit',
      entityId: entityId,
      expectedRevision: 0,
      currentRevision: 0,
      message: root?['message']?.toString() ??
          'Conflit de synchronisation (409).',
    );
  }

  static int _intFrom(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<void> deleteRecordingUnit(String recordingUnitId) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/recording-units/$encoded',
      options: Options(
        headers: {Headers.acceptHeader: 'application/json'},
        validateStatus: (c) => c != null && c < 600,
      ),
    );
    final code = response.statusCode ?? 0;
    if (code == 204 || code == 200) return;

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de supprimer l’unité d’enregistrement (code $code).',
    );
  }

  /// Lie une UE existante comme parente (`POST …/parents`).
  Future<RecordingUnitMobileDetail> linkRecordingUnitParent({
    required String childRecordingUnitId,
    required int parentRecordingUnitId,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(childRecordingUnitId.trim());
    final response = await _postJson(
      '/api/v1/recording-units/$encoded/parents',
      data: {'relatedRecordingUnitId': parentRecordingUnitId},
    );
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      return fetchRecordingUnitDetail(childRecordingUnitId);
    }
    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de lier l’unité parente (code $code).',
    );
  }

  /// Lie une UE existante comme fille (`POST …/children`).
  Future<RecordingUnitMobileDetail> linkRecordingUnitChild({
    required String parentRecordingUnitId,
    required int childRecordingUnitId,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(parentRecordingUnitId.trim());
    final response = await _postJson(
      '/api/v1/recording-units/$encoded/children',
      data: {'relatedRecordingUnitId': childRecordingUnitId},
    );
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      return fetchRecordingUnitDetail(parentRecordingUnitId);
    }
    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de lier l’unité fille (code $code).',
    );
  }

  /// Retire une UE parente (`DELETE …/parents/{relatedId}`).
  Future<RecordingUnitMobileDetail> unlinkRecordingUnitParent({
    required String childRecordingUnitId,
    required int parentRecordingUnitId,
  }) async {
    _ensureReadyForProjectsApi();
    final encodedChild = Uri.encodeComponent(childRecordingUnitId.trim());
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/recording-units/$encodedChild/parents/$parentRecordingUnitId',
      options: Options(
        headers: {Headers.acceptHeader: 'application/json'},
        validateStatus: (c) => c != null && c < 600,
      ),
    );
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 204) {
      return fetchRecordingUnitDetail(childRecordingUnitId);
    }
    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de retirer l’unité parente (code $code).',
    );
  }

  /// Retire une UE fille (`DELETE …/children/{relatedId}`).
  Future<RecordingUnitMobileDetail> unlinkRecordingUnitChild({
    required String parentRecordingUnitId,
    required int childRecordingUnitId,
  }) async {
    _ensureReadyForProjectsApi();
    final encodedParent = Uri.encodeComponent(parentRecordingUnitId.trim());
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/recording-units/$encodedParent/children/$childRecordingUnitId',
      options: Options(
        headers: {Headers.acceptHeader: 'application/json'},
        validateStatus: (c) => c != null && c < 600,
      ),
    );
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 204) {
      return fetchRecordingUnitDetail(parentRecordingUnitId);
    }
    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de retirer l’unité fille (code $code).',
    );
  }

  Future<RecordingUnitMobileDetail> fetchRecordingUnitDetail(
    String recordingUnitId,
  ) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final body = await _getJson('/api/v1/recording-units/$encoded');
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      return RecordingUnitMobileDetail.fromApiData(data);
    }
    if (data is Map) {
      return RecordingUnitMobileDetail.fromApiData(
        Map<String, dynamic>.from(data),
      );
    }
    throw AuthException('Réponse UE invalide.');
  }

  Future<List<ProjectDocumentItem>> fetchRecordingUnitDocuments(
    String recordingUnitId,
  ) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final body = await _getJson('/api/v1/recording-units/$encoded/documents');
    final data = body?['data'];
    if (data is! Map) return const [];

    final docs = data['documents'];
    if (docs is! List) return const [];

    return docs
        .whereType<Map>()
        .map((e) => ProjectDocumentItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MobilierListResult> fetchRecordingUnitMobiliers(
    String recordingUnitId, {
    int offset = 0,
    int limit = 20,
    String sort = 'creationTime:desc',
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(recordingUnitId.trim());
    final body = await _getJson(
      '/api/v1/recording-units/$encoded/mobiliers',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sort,
      },
    );

    final rawList = body?['data'];
    final items = <MobilierItem>[];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is Map) {
          items.add(
            MobilierItem.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final meta = body?['meta'];
    int total = items.length;
    int parsedOffset = offset;
    int parsedLimit = limit;
    if (meta is Map) {
      total = _parseInt(meta['total']) ?? total;
      parsedOffset = _parseInt(meta['offset']) ?? offset;
      parsedLimit = _parseInt(meta['limit']) ?? limit;
    }

    return MobilierListResult(
      items: items,
      total: total,
      offset: parsedOffset,
      limit: parsedLimit,
    );
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<List<ProjectSummary>> fetchAccessibleProjects({
    String? search,
    int? organizationId,
  }) async {
    _ensureReadyForProjectsApi();

    final params = <String, String>{
      'offset': '0',
      'limit': '100',
      'sort': 'name:asc',
    };
    final orgId = organizationId ?? primaryOrganizationId;
    if (orgId != null) {
      params['organizationId'] = orgId.toString();
    }
    final q = search?.trim();
    if (q != null && q.isNotEmpty) {
      params['search'] = q;
    }

    final body = await _getJson(
      '/api/v1/projects',
      queryParameters: params,
    );
    final raw = body?['data'] as List<dynamic>? ?? [];
    return raw
        .map((e) => ProjectSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Organisations accessibles : `GET /api/v1/organizations`.
  Future<List<StoredOrganization>> fetchAccessibleOrganizations({
    int offset = 0,
    int limit = 200,
  }) async {
    _ensureReadyForProjectsApi();

    final body = await _getJson(
      '/api/v1/organizations',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );
    final raw = body?['data'] as List<dynamic>? ?? [];
    final out = <StoredOrganization>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final org = StoredOrganization.tryFromApiResource(
        Map<String, dynamic>.from(entry),
      );
      if (org != null) out.add(org);
    }
    return out;
  }

  /// Met à jour la liste d’organisations du profil après sync API.
  void replaceOrganizationsInProfile(List<StoredOrganization> organizations) {
    final pr = _profile;
    if (pr == null) return;

    final primaryId = pr.primaryOrganizationId;
    String? primaryName = pr.primaryOrganizationName;
    if (primaryId != null) {
      for (final org in organizations) {
        if (org.id == primaryId) {
          primaryName = org.name;
          break;
        }
      }
    }

    _profile = StoredAuthProfile(
      email: pr.email,
      firstName: pr.firstName,
      lastName: pr.lastName,
      username: pr.username,
      personId: pr.personId,
      primaryOrganizationId:
          primaryId ?? (organizations.isNotEmpty ? organizations.first.id : null),
      primaryOrganizationName: primaryName ??
          (organizations.isNotEmpty ? organizations.first.name : null),
      organizations: organizations,
    );
  }

  /// Parents / enfants : `GET /api/v1/recording-units/{id}/relations`.
  Future<RecordingUnitHierarchy> fetchRecordingUnitRelations(
    String recordingUnitId,
  ) async {
    _ensureReadyForProjectsApi();

    final id = recordingUnitId.trim();
    if (id.isEmpty) {
      throw AuthException('Identifiant UE requis pour charger les relations.');
    }

    final encoded = Uri.encodeComponent(id);
    final body = await _getJson('/api/v1/recording-units/$encoded/relations');
    final data = body?['data'];
    if (data is! Map) {
      return RecordingUnitHierarchy(parents: const [], children: const []);
    }
    return RecordingUnitRelationsMapper.fromApiData(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<ConceptOption>> fetchProjectTypeConcepts() async {
    final orgId = primaryOrganizationId;
    if (orgId == null) {
      throw AuthException(
        'Organisation inconnue. Reconnectez-vous pour créer un projet.',
      );
    }

    final db = _db;
    if (db != null) {
      for (final loader in [
        () => db.findValidForm(
              organisationId: orgId,
              type: FormCacheType.vocabulaire,
            ),
        () => db.findLatestForm(
              organisationId: orgId,
              type: FormCacheType.vocabulaire,
            ),
      ]) {
        final types = _projectTypesFromVocabRow(await loader());
        if (types != null && types.isNotEmpty) return types;
      }
    }

    if (!await canUseProjectsApi()) {
      throw AuthException(
        'Types de projet indisponibles hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }

    _ensureReadyForProjectsApi();
    final body = await fetchVocabulariesRaw(organizationId: orgId);
    final data = body['data'];
    if (data is! Map) return const [];

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const [];

    return ConceptOption.projectTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  /// Annuaire organisation : `GET /api/v1/users`.
  Future<OrganizationUsersResult> fetchOrganizationUsers({
    required int organizationId,
    int offset = 0,
    int limit = 100,
    String sort = 'lastname:asc',
    String? search,
  }) async {
    _ensureReadyForProjectsApi();

    final params = <String, String>{
      'organizationId': organizationId.toString(),
      'offset': offset.toString(),
      'limit': limit.toString(),
      'sort': sort,
    };
    final q = search?.trim();
    if (q != null && q.isNotEmpty) {
      params['q'] = q;
    }

    final body = await _getJson('/api/v1/users', queryParameters: params);
    return OrganizationUsersResult.fromJson(body);
  }

  /// Télécharge toutes les pages de l’annuaire (sync démarrage).
  Future<List<PersonOption>> fetchAllOrganizationUsers({
    required int organizationId,
    int pageSize = 100,
  }) async {
    final all = <PersonOption>[];
    var offset = 0;
    while (true) {
      final page = await fetchOrganizationUsers(
        organizationId: organizationId,
        offset: offset,
        limit: pageSize,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      offset += page.items.length;
      if (page.items.length < pageSize) break;
      if (page.total != null && offset >= page.total!) break;
    }
    return all;
  }

  Future<List<SpatialUnitOption>> searchSpatialUnits({
    required int organizationId,
    required String query,
    int limit = 20,
  }) async {
    _ensureReadyForProjectsApi();
    final q = query.trim();
    if (q.length < 2) return const [];

    final body = await _getJson(
      '/api/v1/places/autocomplete',
      queryParameters: {
        'organizationId': organizationId.toString(),
        'q': q,
        'limit': limit.toString(),
      },
    );
    final raw = body?['data'] as List<dynamic>? ?? [];
    return raw
        .map(SpatialUnitOption.fromJson)
        .whereType<SpatialUnitOption>()
        .toList();
  }

  /// Liste paginée des lieux (`GET /api/v1/organizations/{id}/places`).
  Future<OrganizationPlacesResult> fetchOrganizationPlaces({
    required int organizationId,
    int offset = 0,
    int limit = 200,
  }) async {
    _ensureReadyForProjectsApi();
    final encodedOrg = organizationId.toString();
    final body = await _getJson(
      '/api/v1/organizations/$encodedOrg/places',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );
    return OrganizationPlacesResult.fromJson(body);
  }

  /// Télécharge toutes les pages de lieux (sync démarrage).
  Future<List<SpatialUnitOption>> fetchAllOrganizationPlaces({
    required int organizationId,
    int pageSize = 200,
  }) async {
    final all = <SpatialUnitOption>[];
    var offset = 0;
    while (true) {
      final page = await fetchOrganizationPlaces(
        organizationId: organizationId,
        offset: offset,
        limit: pageSize,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      offset += page.items.length;
      if (page.items.length < pageSize) break;
      if (page.total != null && offset >= page.total!) break;
    }
    return all;
  }

  /// Crée un lieu (`POST /api/v1/places`).
  Future<SpatialUnitOption> createSpatialUnit(
    CreateSpatialUnitRequest request,
  ) async {
    _ensureReadyForProjectsApi();
    final response = await _postJson(
      '/api/v1/places',
      data: request.toJson(),
    );

    final code = response.statusCode ?? 0;
    if (kDebugMode && code >= 300 && code < 400) {
      debugPrint(
        '[Siamois] POST /api/v1/places → redirection HTTP $code '
        '(endpoint probablement absent sur le serveur).',
      );
    }
    if (code == 404 ||
        code == 405 ||
        code == 501 ||
        (code >= 300 && code < 400)) {
      throw AuthException(
        'La création de lieux n’est pas encore disponible sur le serveur '
        '(POST /api/v1/places absent ou redirigé — code HTTP $code). '
        'Créez le lieu depuis l’application web Siamois, ou déployez la mise à jour '
        'backend contenant PlaceControllerApi.',
      );
    }
    if (code == 201 || code == 200) {
      final body = _coerceMap(response.data);
      final data = body?['data'] ?? body;
      final parsed = SpatialUnitOption.fromJson(data);
      if (parsed != null) return parsed;
      throw AuthException('Réponse serveur inattendue après création du lieu.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de créer le lieu (code $code).',
    );
  }

  /// Détail d’un lieu (`GET /api/v1/places/{id}`).
  Future<PlaceDetail> fetchPlaceDetail({
    required int organizationId,
    required int placeId,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent('$placeId');
    final body = await _getJson(
      '/api/v1/places/$encoded',
      queryParameters: {'organizationId': '$organizationId'},
    );
    final detail = PlaceDetail.fromJson(body);
    if (detail != null) return detail;
    throw AuthException('Réponse serveur inattendue pour le lieu.');
  }

  /// Modifie un lieu (`PATCH /api/v1/places/{id}`).
  Future<SpatialUnitOption> updateSpatialUnit({
    required int placeId,
    required CreateSpatialUnitRequest request,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent('$placeId');
    final response = await _patchJson(
      '/api/v1/places/$encoded',
      data: request.toJson(),
    );

    final code = response.statusCode ?? 0;
    if (code == 404 || code == 405 || code == 501 || (code >= 300 && code < 400)) {
      throw AuthException(
        'La modification de lieux n’est pas encore disponible sur le serveur '
        '(PATCH /api/v1/places/{id} absent — code HTTP $code).',
      );
    }
    if (code == 200 || code == 201) {
      final body = _coerceMap(response.data);
      final data = body?['data'] ?? body;
      final parsed = SpatialUnitOption.fromJson(data);
      if (parsed != null) return parsed;
      throw AuthException('Réponse serveur inattendue après modification du lieu.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de modifier le lieu (code $code).',
    );
  }

  /// Supprime un lieu (`DELETE /api/v1/places/{id}`).
  Future<void> deleteSpatialUnit({
    required int organizationId,
    required int placeId,
  }) async {
    _ensureReadyForProjectsApi();
    final base = _dio.options.baseUrl.trim();
    final encoded = Uri.encodeComponent('$placeId');
    final uri = Uri.parse('$base/api/v1/places/$encoded').replace(
      queryParameters: {'organizationId': '$organizationId'},
    );

    if (kDebugMode) {
      debugPrint('[Siamois] DELETE $uri');
    }

    try {
      final response = await _dio.deleteUri<Map<String, dynamic>>(
        uri,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 204 || code == 200) return;
      if (code == 404 || code == 405 || code == 501 || (code >= 300 && code < 400)) {
        throw AuthException(
          'La suppression de lieux n’est pas encore disponible sur le serveur '
          '(DELETE /api/v1/places/{id} absent — code HTTP $code).',
        );
      }
      throw _authExceptionFromResponse(
        response,
        fallback: 'Impossible de supprimer le lieu (code $code).',
      );
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'suppression du lieu');
    }
  }

  /// Vocabulaires OpenTheso par field_code (`GET /api/v1/vocabularies`).
  Future<Map<String, List<ConceptOption>>> fetchVocabulariesByFieldCode({
    required int organizationId,
  }) async {
    _ensureReadyForProjectsApi();
    final body = await fetchVocabulariesRaw(organizationId: organizationId);
    final data = body['data'];
    if (data is Map) {
      final vocabs = data['vocabulariesByFieldCode'];
      if (vocabs is Map) {
        return ConceptOption.vocabulariesFromApiMap(
          Map<String, dynamic>.from(vocabs),
        );
      }
    }
    final direct = body['vocabulariesByFieldCode'];
    if (direct is Map) {
      return ConceptOption.vocabulariesFromApiMap(
        Map<String, dynamic>.from(direct),
      );
    }
    return const {};
  }

  /// Autocomplétion de concepts OpenTheso (`GET /api/v1/concepts/autocomplete`).
  Future<List<ConceptOption>> searchConceptAutocomplete({
    required int organizationId,
    required String fieldCode,
    required String query,
    int limit = 20,
  }) async {
    _ensureReadyForProjectsApi();
    final q = query.trim();
    if (q.isEmpty) return const [];

    final body = await _getJsonOptional(
      '/api/v1/concepts/autocomplete',
      queryParameters: {
        'organizationId': organizationId.toString(),
        'fieldCode': fieldCode.trim(),
        'q': q,
        'limit': limit.toString(),
      },
    );
    if (body == null) return const [];

    final raw = body['data'] as List<dynamic>? ?? [];
    return raw
        .map(ConceptOption.fromAutocompleteJson)
        .whereType<ConceptOption>()
        .toList();
  }

  /// Autocomplétion d'adresses (API serveur ou GeoPlat).
  Future<List<FullAddressOption>> searchAddressSuggestions(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    if (await canUseProjectsApi()) {
      try {
        final body = await _getJsonOptional(
          '/api/v1/addresses/autocomplete',
          queryParameters: {
            'q': q,
            'limit': '7',
          },
        );
        if (body != null) {
          final raw = body['data'] as List<dynamic>? ?? [];
          final parsed = raw
              .map(FullAddressOption.fromJson)
              .whereType<FullAddressOption>()
              .toList();
          if (parsed.isNotEmpty) return parsed;
        }
      } on AuthException {
        // Repli GeoPlat ci-dessous.
      }
    }

    return _searchGeoPlatAddresses(q);
  }

  static final Dio _geoPlatDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  Future<List<FullAddressOption>> _searchGeoPlatAddresses(String query) async {
    try {
      final response = await _geoPlatDio.get<Map<String, dynamic>>(
        'https://data.geopf.fr/geocodage/completion',
        queryParameters: {
          'text': query,
          'maximumResponses': 7,
          'type': 'StreetAddress',
        },
      );
      final results = response.data?['results'];
      if (results is! List) return const [];

      final out = <FullAddressOption>[];
      for (final item in results) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final label = map['fulltext']?.toString().trim();
        if (label == null || label.isEmpty) continue;
        out.add(
          FullAddressOption(
            label: label,
            street: map['street']?.toString(),
            postcode: map['zipcode']?.toString(),
            city: map['city']?.toString(),
            lon: _parseGeoDouble(map['x']),
            lat: _parseGeoDouble(map['y']),
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  double? _parseGeoDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  Future<ProjectSummary> patchProject({
    required String projectId,
    required ProjectPatchPayload payload,
  }) async {
    _ensureReadyForProjectsApi();
    final encoded = Uri.encodeComponent(projectId.trim());
    final response = await _patchJson(
      '/api/v1/projects/$encoded',
      data: payload.toJson(),
    );

    final code = response.statusCode ?? 0;
    if (code == 200) {
      final item = response.data?['data'];
      if (item is Map<String, dynamic>) {
        return ProjectSummary.fromJson(item);
      }
      if (item is Map) {
        return ProjectSummary.fromJson(Map<String, dynamic>.from(item));
      }
      throw AuthException('Réponse serveur inattendue après modification.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de modifier le projet (code $code).',
    );
  }

  Future<ProjectSummary> createProjectFromPayload(
    ProjectCreatePayload payload,
  ) async {
    return createProject(
      organizationId: payload.organizationId,
      name: payload.name,
      identifier: payload.identifier,
      typeConceptId: payload.typeConceptId,
      beginDate: payload.beginDate,
      endDate: payload.endDate,
      spatialContextSpatialUnitIds: payload.spatialContextSpatialUnitIds,
      fieldAnswers: payload.fieldAnswers,
    );
  }

  Future<ProjectSummary> createProject({
    required int organizationId,
    required String name,
    required String identifier,
    required int typeConceptId,
    DateTime? beginDate,
    DateTime? endDate,
    List<int> spatialContextSpatialUnitIds = const [],
    Map<String, dynamic> fieldAnswers = const {},
  }) async {
    _ensureReadyForProjectsApi();

    final response = await _postJson(
      '/api/v1/projects',
      data: {
        'organizationId': organizationId,
        'name': name.trim(),
        'identifier': identifier.trim(),
        'typeConceptId': typeConceptId,
        if (beginDate != null)
          'beginDate': beginDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (spatialContextSpatialUnitIds.isNotEmpty)
          'spatialContextSpatialUnitIds': spatialContextSpatialUnitIds,
        if (fieldAnswers.isNotEmpty) 'fieldAnswers': fieldAnswers,
      },
    );

    final code = response.statusCode ?? 0;
    if (code == 201 || code == 200) {
      final item = response.data?['data'];
      if (item is Map<String, dynamic>) {
        return ProjectSummary.fromJson(item);
      }
      throw AuthException('Réponse serveur inattendue après création.');
    }

    throw _authExceptionFromResponse(
      response,
      fallback: 'Impossible de créer le projet (code $code).',
    );
  }

  void _ensureReadyForProjectsApi() {
    if (!_initialized) {
      throw StateError(
        'AuthRepository.init() doit être appelé avant les appels projets.',
      );
    }
    _requireConfiguredServerBaseUrl();
  }

  Future<Map<String, dynamic>?> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base$path').replace(
      queryParameters: queryParameters,
    );

    if (kDebugMode) {
      debugPrint('[Siamois] GET $uri');
    }

    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      return await _parseJsonResponse(response, context: 'chargement');
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'chargement');
    }
  }

  /// Comme [_getJson] mais ne lève pas d’exception (lecture optionnelle).
  ///
  /// Tolère les endpoints absents (404/501), les réponses non JSON et les
  /// erreurs réseau transitoires.
  Future<Map<String, dynamic>?> _getJsonOptional(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base$path').replace(
      queryParameters: queryParameters,
    );

    if (kDebugMode) {
      debugPrint('[Siamois] GET (optionnel) $uri');
    }

    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(
          headers: {Headers.acceptHeader: 'application/json'},
          responseType: ResponseType.plain,
          validateStatus: (c) => c != null && c < 600,
        ),
      );
      final code = response.statusCode ?? 0;
      if (code == 404 || code == 501) return null;
      if (code == 401 || code == 403) return null;
      if (code != 200) return null;
      final body = _coerceMap(response.data);
      return body;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 501) return null;
      if (kDebugMode) {
        debugPrint(
          '[Siamois] GET optionnel indisponible ($path)'
          '${code != null ? ' (HTTP $code)' : ''}',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _ensureThesaurusConfigSaved(
    Response<dynamic> response, {
    String fallback = 'Impossible d’enregistrer la configuration du thésaurus.',
  }) {
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 204) return;
    if (code == 404 || code == 501 || (code >= 300 && code < 400)) {
      throw AuthException(
        'Endpoint thésaurus indisponible sur le serveur (code $code).',
      );
    }
    throw AuthException(
      _readApiErrorMessage(response.data) ?? '$fallback (code $code).',
    );
  }

  Future<Response<dynamic>> _putThesaurusJson(
    String path, {
    required Map<String, dynamic> data,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base$path');

    if (kDebugMode) {
      debugPrint('[Siamois] PUT $uri');
    }

    try {
      final response = await _dio.putUri<dynamic>(
        uri,
        data: data,
        options: Options(
          headers: {
            Headers.acceptHeader: 'application/json',
            Headers.contentTypeHeader: 'application/json',
          },
          responseType: ResponseType.plain,
          followRedirects: true,
          maxRedirects: 5,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (c) => c != null && c < 600,
        ),
        onSendProgress: onSendProgress,
      );
      if (kDebugMode) {
        debugPrint('[Siamois] PUT $uri → HTTP ${response.statusCode}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        final code = e.response?.statusCode;
        debugPrint(
          '[Siamois] PUT $uri échoué'
          '${code != null ? ' (HTTP $code)' : ''}: ${e.type.name}',
        );
      }
      throw _authExceptionFromDio(e, context: 'enregistrement');
    }
  }

  Future<Response<Map<String, dynamic>>> _patchJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base$path');

    if (kDebugMode) {
      debugPrint('[Siamois] PATCH $uri');
    }

    try {
      return await _dio.patchUri<Map<String, dynamic>>(
        uri,
        data: data,
        options: Options(
          headers: {
            Headers.acceptHeader: 'application/json',
            Headers.contentTypeHeader: 'application/json',
          },
          validateStatus: (c) => c != null && c < 600,
        ),
      );
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'modification');
    }
  }

  Future<Response<Map<String, dynamic>>> _postJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final base = _dio.options.baseUrl.trim();
    final uri = Uri.parse('$base$path');

    if (kDebugMode) {
      debugPrint('[Siamois] POST $uri');
    }

    try {
      return await _dio.postUri<Map<String, dynamic>>(
        uri,
        data: data,
        options: Options(
          headers: {
            Headers.acceptHeader: 'application/json',
            Headers.contentTypeHeader: 'application/json',
          },
          validateStatus: (c) => c != null && c < 600,
        ),
      );
    } on DioException catch (e) {
      throw _authExceptionFromDio(e, context: 'création');
    }
  }

  Future<Map<String, dynamic>?> _parseJsonResponse(
    Response<Map<String, dynamic>> response, {
    required String context,
  }) async {
    final code = response.statusCode ?? 0;
    if (code == 401) {
      if (!_isWithinFreshTokenGrace()) {
        await _clearMemoryAndPrefs();
      }
      throw AuthException(
        _readApiErrorMessage(response.data) ??
            'Accès refusé. Vérifiez vos droits ou reconnectez-vous.',
      );
    }
    if (code == 400) {
      throw AuthException(
        _readApiErrorMessage(response.data) ??
            'Requête invalide ou contexte institution manquant.',
      );
    }
    if (code == 403) {
      throw AuthException(
        _readApiErrorMessage(response.data) ??
            'Action non autorisée pour votre compte.',
      );
    }
    if (code != 200) {
      throw AuthException(
        _readApiErrorMessage(response.data) ??
            'Impossible le $context (code $code).',
      );
    }
    return response.data;
  }

  AuthException _authExceptionFromResponse(
    Response<Map<String, dynamic>> response, {
    required String fallback,
  }) {
    return AuthException(_readApiErrorMessage(response.data) ?? fallback);
  }

  AuthException _authExceptionFromDio(
    DioException e, {
    required String context,
  }) {
    if (e.type == DioExceptionType.cancel && e.message != null) {
      return AuthException(e.message!);
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return AuthException(
        _readApiErrorMessage(e.response?.data) ??
            'Accès refusé. Vérifiez vos droits ou reconnectez-vous.',
      );
    }
    return AuthException(
      _readApiErrorMessage(e.response?.data) ??
          (e.message?.isNotEmpty == true
              ? e.message!
              : 'Erreur réseau lors du $context.'),
    );
  }

  static Map<String, dynamic>? _coerceMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().startsWith('{')) {
      try {
        final d = jsonDecode(data);
        if (d is Map<String, dynamic>) return d;
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  static String? _msgFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final m = json['message'];
    if (m is String && m.isNotEmpty) return m;
    final err = json['error'];
    if (err is String && err.isNotEmpty) return err;
    return null;
  }

  static String? _readApiErrorMessage(dynamic body) {
    return _msgFromJson(_coerceMap(body));
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
