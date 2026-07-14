/// Réponse de `GET /api/v1/users/me/thesaurus`.
class UserThesaurusInfo {
  const UserThesaurusInfo({
    required this.thesaurusUrl,
    required this.userConfigured,
    this.label,
  });

  final String thesaurusUrl;
  final bool userConfigured;
  final String? label;

  UserThesaurusInfo copyWith({
    String? thesaurusUrl,
    bool? userConfigured,
    String? label,
  }) {
    return UserThesaurusInfo(
      thesaurusUrl: thesaurusUrl ?? this.thesaurusUrl,
      userConfigured: userConfigured ?? this.userConfigured,
      label: label ?? this.label,
    );
  }

  factory UserThesaurusInfo.fromJson(Map<String, dynamic>? body) {
    if (body == null) {
      return const UserThesaurusInfo(thesaurusUrl: '', userConfigured: false);
    }

    final data = body['data'];
    if (data is Map) {
      final userConfigured = data['userConfigured'] == true;
      final thesaurus = data['thesaurus'];
      if (thesaurus is Map) {
        final uri = thesaurus['uri']?.toString().trim() ?? '';
        final label = thesaurus['label']?.toString().trim();
        if (uri.isNotEmpty) {
          return UserThesaurusInfo(
            thesaurusUrl: uri,
            userConfigured: userConfigured,
            label: label?.isNotEmpty == true ? label : null,
          );
        }
      }

      return UserThesaurusInfo(
        thesaurusUrl: _readLegacyUrl(data) ?? _readLegacyUrl(body) ?? '',
        userConfigured: userConfigured,
      );
    }

    return UserThesaurusInfo(
      thesaurusUrl: _readLegacyUrl(body) ?? '',
      userConfigured: body['userConfigured'] == true,
      label: body['label']?.toString().trim(),
    );
  }

  static String? _readLegacyUrl(Map<dynamic, dynamic> map) {
    final url = map['thesaurusUrl'] ?? map['url'];
    if (url == null) return null;
    final s = url.toString().trim();
    return s.isEmpty ? null : s;
  }
}
