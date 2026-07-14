/// Option de vocabulaire (concept) pour les listes déroulantes.
class ConceptOption {
  const ConceptOption({required this.id, required this.label});

  final int id;
  final String label;

  static const _prefLabelType = 'PREF_LABEL';

  static ConceptOption? fromAutocompleteJson(dynamic raw) {
    final parsed = _parseRawEntry(raw);
    if (parsed != null) {
      return ConceptOption(id: parsed.conceptId, label: parsed.label);
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final id = _parseId(map['id'] ?? map['conceptId']);
      final label = _string(map['label'] ?? map['name']);
      if (id != null && label != null && label.isNotEmpty) {
        return ConceptOption(id: id, label: label);
      }
    }
    return null;
  }

  /// Parse une liste vocabulaire API en dédoublonnant par `concept.externalId`.
  static List<ConceptOption> fromRawVocabularyList(List<dynamic> raw) {
    final parsed = <_ParsedConceptLabel>[];
    for (final item in raw) {
      final entry = _parseRawEntry(item);
      if (entry != null) parsed.add(entry);
    }
    return _dedupeByConceptExternalId(parsed)
        .map((e) => ConceptOption(id: e.conceptId, label: e.label))
        .toList();
  }

  /// Construit `fieldCode → options` depuis `vocabulariesByFieldCode`.
  static Map<String, List<ConceptOption>> vocabulariesFromApiMap(
    Map<String, dynamic> vocabulariesByFieldCode,
  ) {
    final out = <String, List<ConceptOption>>{};
    for (final entry in vocabulariesByFieldCode.entries) {
      final list = entry.value;
      if (list is List) {
        out[entry.key] = fromRawVocabularyList(list);
      }
    }
    return out;
  }

  /// Extrait les types d'UE depuis `vocabulariesByFieldCode` (`SIARU.TYPE`).
  static List<ConceptOption> recordingUnitTypesFromVocabularies(
    Map<String, dynamic> vocabulariesByFieldCode,
  ) {
    const preferredKeys = ['SIARU.TYPE', 'SIARU_TYPE', 'typeConcept'];
    for (final key in preferredKeys) {
      final options = _optionsForKey(vocabulariesByFieldCode, key);
      if (options.isNotEmpty) return options;
    }

    for (final entry in vocabulariesByFieldCode.entries) {
      final upper = entry.key.toUpperCase();
      if (upper.contains('SIARU') && upper.contains('TYPE')) {
        final options = _optionsForKey(vocabulariesByFieldCode, entry.key);
        if (options.isNotEmpty) return options;
      }
    }

    return const [];
  }

  /// Extrait les types de projet depuis `vocabulariesByFieldCode`.
  static List<ConceptOption> projectTypesFromVocabularies(
    Map<String, dynamic> vocabulariesByFieldCode,
  ) {
    const preferredKeys = ['SIAAU.TYPE', 'typeConcept', 'TYPE'];
    for (final key in preferredKeys) {
      final options = _optionsForKey(vocabulariesByFieldCode, key);
      if (options.isNotEmpty) return options;
    }

    for (final entry in vocabulariesByFieldCode.entries) {
      if (entry.key.toUpperCase().contains('TYPE')) {
        final options = _optionsForKey(vocabulariesByFieldCode, entry.key);
        if (options.isNotEmpty) return options;
      }
    }

    return const [];
  }

  /// Options pour un `fieldCode` OpenTheso (recherche insensible à la casse).
  static List<ConceptOption> optionsForFieldCode(
    Map<String, List<ConceptOption>> vocabByCode,
    String fieldCode,
  ) {
    final key = fieldCode.trim();
    if (key.isEmpty) return const [];

    final direct = vocabByCode[key];
    if (direct != null && direct.isNotEmpty) return direct;

    final upper = key.toUpperCase();
    for (final entry in vocabByCode.entries) {
      if (entry.key.toUpperCase() == upper && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return const [];
  }

  /// Filtre local par libellé (remplace l’ancien autocomplete concepts).
  static List<ConceptOption> filterByQuery(
    List<ConceptOption> options,
    String query, {
    int limit = 20,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return options.take(limit).toList();
    return options
        .where((o) => o.label.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  /// Catégories de lieu (`SIASU.TYPE`) depuis `vocabulariesByFieldCode`.
  static List<ConceptOption> spatialUnitCategoriesFromVocabularies(
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    const preferredKeys = ['SIASU.TYPE', 'SIASU_TYPE', 'category'];
    for (final key in preferredKeys) {
      final options = vocabByCode[key];
      if (options != null && options.isNotEmpty) return options;
    }

    for (final entry in vocabByCode.entries) {
      final upper = entry.key.toUpperCase();
      if (upper.contains('SIASU') && upper.contains('TYPE')) {
        if (entry.value.isNotEmpty) return entry.value;
      }
    }
    return const [];
  }

  static List<ConceptOption> _optionsForKey(
    Map<String, dynamic> map,
    String key,
  ) {
    final raw = map[key];
    if (raw is! List) return const [];
    return fromRawVocabularyList(raw);
  }

  /// Si plusieurs libellés partagent le même `concept.externalId`, ne garde que
  /// ceux en `PREF_LABEL` (sinon le premier libellé disponible).
  static List<_ParsedConceptLabel> _dedupeByConceptExternalId(
    List<_ParsedConceptLabel> items,
  ) {
    final groups = <String, List<_ParsedConceptLabel>>{};
    for (final item in items) {
      final ext = item.conceptExternalId?.trim();
      final key = ext != null && ext.isNotEmpty
          ? 'ext:$ext'
          : 'id:${item.conceptId}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final out = <_ParsedConceptLabel>[];
    for (final group in groups.values) {
      if (group.length <= 1) {
        out.add(group.first);
        continue;
      }
      final pref = group
          .where((e) => e.labelType == _prefLabelType)
          .toList();
      if (pref.isNotEmpty) {
        out.addAll(pref);
      } else {
        out.add(group.first);
      }
    }
    return out;
  }

  static _ParsedConceptLabel? _parseRawEntry(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final labelDto = map['conceptLabelToDisplay'];
    if (labelDto is! Map) return null;
    final dto = Map<String, dynamic>.from(labelDto);

    int? conceptId;
    String? conceptExternalId;
    final concept = dto['concept'];
    if (concept is Map) {
      final c = Map<String, dynamic>.from(concept);
      conceptId = _parseId(c['id']);
      conceptExternalId = _string(c['externalId']);
    }

    var label = _string(dto['label']) ?? '';
    if (label.isEmpty) {
      label = _string(map['originalPrefLabel']) ?? '';
    }

    conceptId ??= _parseId(map['id']);
    if (conceptId == null || label.isEmpty) return null;

    return _ParsedConceptLabel(
      conceptId: conceptId,
      label: label,
      conceptExternalId: conceptExternalId,
      labelType: _string(dto['labelType']),
    );
  }

  static int? _parseId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class _ParsedConceptLabel {
  const _ParsedConceptLabel({
    required this.conceptId,
    required this.label,
    this.conceptExternalId,
    this.labelType,
  });

  final int conceptId;
  final String label;
  final String? conceptExternalId;
  final String? labelType;
}
