class ProjectSummary {
  ProjectSummary({
    required this.id,
    required this.name,
    this.fullIdentifier,
    this.identifier,
    this.recordingUnitCount,
  });

  final String id;
  final String name;
  final String? fullIdentifier;
  final String? identifier;

  /// Nombre d’unités d’enregistrement (`recordingUnitList.meta.count`).
  final int? recordingUnitCount;

  String get displayCode => fullIdentifier ?? identifier ?? id;

  /// Clé stable pour SQLite (l’API peut renvoyer un `id` vide).
  String get storageId {
    final raw = id.trim();
    if (raw.isNotEmpty) return raw;
    final full = fullIdentifier?.trim();
    if (full != null && full.isNotEmpty) return full;
    final short = identifier?.trim();
    if (short != null && short.isNotEmpty) return short;
    return 'sans-id-${name.trim().hashCode}';
  }

  /// Libellé accessible (VoiceOver / tooltip sur la pastille UE).
  String? get recordingUnitCountSemanticLabel {
    final n = recordingUnitCount;
    if (n == null) return null;
    if (n == 0) return 'Aucune unité d’enregistrement';
    if (n == 1) return '1 unité d’enregistrement';
    return '$n unités d’enregistrement';
  }

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Sans titre',
      fullIdentifier: json['fullIdentifier'] as String?,
      identifier: json['identifier'] as String?,
      recordingUnitCount: _parseRecordingUnitCount(json),
    );
  }

  static int? _parseRecordingUnitCount(Map<String, dynamic> json) {
    final rel = json['recordingUnitList'];
    if (rel is! Map) return null;
    final meta = rel['meta'];
    if (meta is! Map) return null;
    final count = meta['count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return null;
  }
}
