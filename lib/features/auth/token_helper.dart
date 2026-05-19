import 'dart:convert';

/// Marge avant expiration pour renouveler le jeton (évite les 401 en cours de requête).
const kTokenExpirySkew = Duration(seconds: 60);

/// Lit le claim `exp` (secondes Unix) d’un JWT sans vérifier la signature.
DateTime? jwtExpirationUtc(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final map = jsonDecode(payload);
    if (map is! Map) return null;
    final exp = map['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
          .toLocal();
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
              isUtc: true)
          .toLocal();
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// `true` si le jeton est absent, expiré ou expire dans [skew].
///
/// On se fie d’abord à [expiresAt] (champ `expiresIn` du login). Le claim JWT
/// n’est utilisé qu’en secours : évite les re-logins en boucle si les deux
/// dates divergent légèrement.
bool tokenNeedsRefresh({
  required String? accessToken,
  DateTime? expiresAt,
  Duration skew = kTokenExpirySkew,
}) {
  if (accessToken == null || accessToken.trim().isEmpty) return true;

  final threshold = DateTime.now().add(skew);

  if (expiresAt != null) {
    return !threshold.isBefore(expiresAt);
  }

  final jwtExp = jwtExpirationUtc(accessToken);
  if (jwtExp != null) {
    return !threshold.isBefore(jwtExp);
  }

  return false;
}
