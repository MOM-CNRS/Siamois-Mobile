import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../features/auth/auth_repository.dart';

/// Détection réseau : interface disponible + ping réel du serveur Siamois.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, Dio? probeDio})
      : _connectivity = connectivity ?? Connectivity(),
        _probeDio = probeDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
                followRedirects: true,
                validateStatus: (code) => code != null && code < 600,
              ),
            );

  final Connectivity _connectivity;
  final Dio _probeDio;

  Future<bool> hasNetworkInterface() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Ping léger : toute réponse HTTP du serveur (y compris 401/404) = joignable.
  Future<bool> canReachServer(String baseUrl) async {
    final root = AuthRepository.normalizeBaseUrl(baseUrl);
    if (root.isEmpty) return false;

    final targets = <Uri>[
      Uri.parse('$root/api/v1/vocabularies'),
      Uri.parse(root),
    ];

    for (final uri in targets) {
      try {
        await _probeDio.getUri<void>(
          uri,
          options: Options(
            extra: const {'skipAuth': true},
            headers: {Headers.acceptHeader: 'application/json'},
          ),
        );
        return true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code != null && code > 0) return true;
      } catch (_) {
        /* essayer l’URL suivante */
      }
    }
    return false;
  }

  Future<bool> isOnline(String baseUrl) async {
    if (!await hasNetworkInterface()) return false;
    return canReachServer(baseUrl);
  }
}
