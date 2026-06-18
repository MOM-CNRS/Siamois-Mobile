/// Périmètre de la configuration thésaurus (utilisateur).
enum ThesaurusSettingsScope {
  user('user');

  const ThesaurusSettingsScope(this.storageKey);

  final String storageKey;

  bool get isUser => this == ThesaurusSettingsScope.user;
}
