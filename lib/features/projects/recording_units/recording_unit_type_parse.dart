/// Extraction de l’identifiant concept « type d’UE » depuis les réponses OpenAPI.
int? recordingUnitTypeConceptIdFromRelationship(dynamic rel) {
  if (rel is! Map) return null;
  final map = Map<String, dynamic>.from(rel);

  final data = map['data'];
  if (data is Map) {
    final id = _parseConceptId(Map<String, dynamic>.from(data));
    if (id != null) return id;
  }

  return _parseConceptId(map);
}

int? _parseConceptId(Map<String, dynamic> map) {
  final candidates = [
    map['conceptId'],
    map['concept_id'],
    map['resourceId'],
    map['id'],
  ];
  for (final raw in candidates) {
    final id = _parseId(raw);
    if (id != null) return id;
  }
  return null;
}

int? _parseId(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  final s = raw?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return int.tryParse(s);
}
