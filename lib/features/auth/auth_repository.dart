import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/server_config.dart';
import '../../core/database/app_database.dart';
import '../../core/database/local_auth_store.dart';
import '../../core/database/tables.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/sync/sync_conflict_exception.dart';
import '../projects/form/person_option.dart';
import '../projects/form/project_form_models.dart';
import '../projects/documents/document_open_helper.dart';
import '../projects/project_detail_models.dart';
import '../projects/recording_units/recording_unit_detail_models.dart';
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
    _applyBuiltInServerUrl();
    _initialized = true;
  }

  void _applyBuiltInServerUrl() {
    final normalized = normalizeBaseUrl(kSiamoisServerBaseUrl);
    _dio.options.baseUrl = normalized;
    _lastPersistedBaseUrl = normalized;
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
      throw AuthException('Non connecté. Identifiez-vous.');
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
    _lastPersistedBaseUrl = p.getString(_kPrefBaseUrl) ?? '';
    if (_lastPersistedBaseUrl.isNotEmpty) {
      _dio.options.baseUrl = normalizeBaseUrl(_lastPersistedBaseUrl);
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
    if (em.isNotEmpty || fn.isNotEmpty || ln.isNotEmpty) {
      _profile = StoredAuthProfile(
        email: em,
        firstName: fn,
        lastName: ln,
        primaryOrganizationId: oid,
        primaryOrganizationName: (on == null || on.isEmpty) ? null : on,
      );
    } else {
      _profile = null;
    }

    // Pas de login silencieux ici : évite plusieurs POST /login au démarrage.
    if (tokenNeedsRefresh(
      accessToken: _accessToken,
      expiresAt: _accessTokenExpiresAt,
    )) {
      _accessToken = null;
      _accessTokenExpiresAt = null;
      await p.remove(_kPrefAccessToken);
      await p.remove(_kPrefExpiresAtMs);
    }
  }

  /// Reprend la session si le jeton en cache est encore valide (sans re-login).
  Future<bool> resumeSessionIfValid() async {
    if (!_initialized) await init();
    if ((_accessToken ?? '').isEmpty ||
        _dio.options.baseUrl.trim().isEmpty) {
      return false;
    }
    return !tokenNeedsRefresh(
      accessToken: _accessToken,
      expiresAt: _accessTokenExpiresAt,
    );
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
    _applyBuiltInServerUrl();
    await p.remove(_kPrefBaseUrl);
    await p.remove(_kPrefAccessToken);
    await p.remove(_kPrefExpiresAtMs);
    await p.remove(_kPrefOrgId);
    await p.remove(_kPrefOrgName);
    await p.remove(_kPrefFirstName);
    await p.remove(_kPrefLastName);
    await p.remove(_kPrefEmail);
    await _credentials.clear();
  }

  static String normalizeBaseUrl(String input) {
    var s = input.trim();
    if (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
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

    _applyBuiltInServerUrl();
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

    _profile =
        StoredAuthProfile.fromLoginJson(json) ??
        StoredAuthProfile(
          email: fallbackEmail,
          firstName: '',
          lastName: '',
        );
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

  Future<Map<String, dynamic>> fetchVocabulariesRaw({
    required int organizationId,
  }) async {
    final body = await _getJson(
      '/api/v1/vocabularies',
      queryParameters: {'organizationId': organizationId.toString()},
    );
    return body ?? {};
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
      final body = await _getJson('/api/v1/mobiliers/$encoded');
      return body ?? {};
    }
    final body = await _getJson(
      '/api/v1/mobiliers/form',
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
      '/api/v1/mobiliers',
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
    required int specimenId,
    Map<String, dynamic> fieldAnswers = const {},
  }) async {
    _ensureReadyForProjectsApi();
    final response = await _patchJson(
      '/api/v1/mobiliers/$specimenId',
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

  Future<void> deleteMobilier(int specimenId) async {
    _ensureReadyForProjectsApi();
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/mobiliers/$specimenId',
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

  Future<ProjectDocumentItem> updateDocument({
    required String documentId,
    required Map<String, dynamic> payload,
  }) async {
    _ensureReadyForProjectsApi();
    final id = documentId.trim();
    final response = await _patchJson('/api/v1/documents/$id', data: payload);
    final code = response.statusCode ?? 0;
    if (code == 200) {
      final data = response.data?['data'];
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
      final cached = await db.findValidForm(
        organisationId: orgId,
        type: FormCacheType.vocabulaire,
      );
      if (cached != null) {
        final map = db.decodeFormMap(cached);
        final data = map?['data'];
        if (data is Map) {
          final vocabs = data['vocabulariesByFieldCode'];
          if (vocabs is Map) {
            return ConceptOption.recordingUnitTypesFromVocabularies(
              Map<String, dynamic>.from(vocabs),
            );
          }
        }
      }
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

  Future<List<ConceptOption>> fetchProjectTypeConcepts() async {
    final orgId = primaryOrganizationId;
    if (orgId == null) {
      throw AuthException(
        'Organisation inconnue. Reconnectez-vous pour créer un projet.',
      );
    }

    final db = _db;
    if (db != null) {
      final cached = await db.findValidForm(
        organisationId: orgId,
        type: FormCacheType.vocabulaire,
      );
      if (cached != null) {
        final map = db.decodeFormMap(cached);
        final data = map?['data'];
        if (data is Map) {
          final vocabs = data['vocabulariesByFieldCode'];
          if (vocabs is Map) {
            return ConceptOption.projectTypesFromVocabularies(
              Map<String, dynamic>.from(vocabs),
            );
          }
        }
      }
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
      '/api/v1/spatial-units/autocomplete',
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
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw AuthException('URL du serveur inconnue. Reconnectez-vous.');
    }
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
