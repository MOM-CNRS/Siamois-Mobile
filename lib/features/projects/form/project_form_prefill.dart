import '../vocabulary_models.dart';
import 'project_form_models.dart';

/// Pré-remplit [ProjectFormState] depuis la réponse `GET /api/v1/projects/{id}`.
abstract final class ProjectFormPrefill {
  static void apply(
    ProjectFormState state,
    ProjectFormDefinition definition,
    Map<String, dynamic> project, {
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    for (final field in definition.fields) {
      final binding = field.valueBinding?.trim();
      if (binding == null || binding.isEmpty) continue;

      switch (field.normalizedType) {
        case ProjectAnswerType.text:
          final value = _textForBinding(binding, project);
          if (value != null) {
            state.textValues[field.key] = value;
          }
        case ProjectAnswerType.dateTime:
          if (binding == 'beginDate') {
            state.dateValues[field.key] = _parseDate(project['beginDate']);
          } else if (binding == 'endDate') {
            state.dateValues[field.key] = _parseDate(project['endDate']);
          }
        case ProjectAnswerType.selectOneFromFieldCode:
          final conceptId = _conceptIdForField(
            field: field,
            binding: binding,
            project: project,
            vocabByCode: vocabByCode,
          );
          if (conceptId != null) {
            state.conceptValues[field.key] = conceptId;
          }
        case ProjectAnswerType.selectOneSpatialUnit:
          if (binding == 'mainLocation') {
            final su = _spatialUnit(project['mainLocation']);
            if (su != null) {
              state.spatialSingleValues[field.key] = su;
            }
          }
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          if (binding == 'spatialContext') {
            state.spatialMultiValues[field.key] =
                _spatialContextUnits(project);
          }
        default:
          break;
      }
    }
  }

  static int? _conceptIdForField({
    required ProjectFormField field,
    required String binding,
    required Map<String, dynamic> project,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    if (_isProjectTypeField(field, binding)) {
      return _resolveProjectTypeConceptId(
        project,
        field: field,
        vocabByCode: vocabByCode,
      );
    }

    final direct = _conceptId(project[binding]);
    if (direct != null) return direct;

    final conceptKey = binding.endsWith('Concept')
        ? binding
        : '${binding}Concept';
    final fromConceptKey = _conceptId(project[conceptKey]);
    if (fromConceptKey != null) return fromConceptKey;

    final label = _conceptDisplayLabel(project[conceptKey]) ??
        _conceptDisplayLabel(project[binding]);
    if (label != null && vocabByCode != null) {
      return _matchConceptByLabel(label, field, vocabByCode);
    }
    return null;
  }

  static bool _isProjectTypeField(ProjectFormField field, String binding) {
    if (binding == 'type') return true;
    final code = field.fieldCode?.trim().toUpperCase();
    return code == 'SIAAU.TYPE' || code == 'SIAAU_TYPE';
  }

  static int? _resolveProjectTypeConceptId(
    Map<String, dynamic> project, {
    required ProjectFormField field,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final directId = _parseInt(project['typeConceptId']);
    if (directId != null) return directId;

    final fromTypeConcept = _conceptId(project['typeConcept']);
    if (fromTypeConcept != null) return fromTypeConcept;

    final typeRel = project['type'];
    if (typeRel is Map) {
      final fromRel = _conceptId(typeRel);
      if (fromRel != null) return fromRel;
    }

    final label = _conceptDisplayLabel(project['typeConcept']) ??
        _string(project['categorie']);
    if (label != null && vocabByCode != null) {
      return _matchConceptByLabel(label, field, vocabByCode);
    }
    return null;
  }

  static int? _matchConceptByLabel(
    String label,
    ProjectFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final options = _optionsForField(field, vocabByCode);
    for (final option in options) {
      if (option.label.trim().toLowerCase() == normalized) {
        return option.id;
      }
    }
    return null;
  }

  static List<ConceptOption> _optionsForField(
    ProjectFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final code = field.fieldCode?.trim();
    if (code != null && code.isNotEmpty) {
      final fromCode = vocabByCode[code];
      if (fromCode != null && fromCode.isNotEmpty) return fromCode;
    }
    return vocabByCode['SIAAU.TYPE'] ?? const [];
  }

  static String? _textForBinding(String binding, Map<String, dynamic> project) {
    switch (binding) {
      case 'name':
        return project['name']?.toString();
      case 'identifier':
        return project['identifier']?.toString() ??
            project['fullIdentifier']?.toString();
      default:
        return null;
    }
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static int? _conceptId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    for (final key in const ['conceptId', 'id', 'resourceId']) {
      final parsed = _parseInt(map[key]);
      if (parsed != null) return parsed;
    }

    final concept = map['concept'];
    if (concept is Map) {
      final nested = _conceptId(concept);
      if (nested != null) return nested;
    }

    final data = map['data'];
    if (data is Map) {
      return _conceptId(data);
    }
    return null;
  }

  static String? _conceptDisplayLabel(dynamic raw) {
    if (raw is! Map) return null;
    return _string(raw['displayLabel']);
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static SpatialUnitOption? _spatialUnit(dynamic rel) {
    if (rel is! Map) return null;
    final map = Map<String, dynamic>.from(rel);
    // JSON:API relationship : { data: { id, name, ... } }
    final data = map['data'];
    if (data is Map) {
      return _spatialUnitFromMap(Map<String, dynamic>.from(data));
    }
    // PlaceLightResource plat renvoyé par GET /projects/{id}
    return _spatialUnitFromMap(map);
  }

  static SpatialUnitOption? _spatialUnitFromMap(Map<String, dynamic> map) {
    final id = _parseInt(map['id'] ?? map['resourceId']);
    if (id == null) return null;

    final name = _string(map['name']) ?? 'Lieu $id';
    return SpatialUnitOption(
      id: id,
      label: name,
      code: _string(map['code']),
    );
  }

  static List<SpatialUnitOption> _spatialContextUnits(
    Map<String, dynamic> project,
  ) {
    final rel = project['spatialContext'];
    final List rawItems;
    if (rel is List) {
      rawItems = rel;
    } else if (rel is Map) {
      final data = rel['data'];
      if (data is! List) return const [];
      rawItems = data;
    } else {
      return const [];
    }

    final units = <SpatialUnitOption>[];
    for (final item in rawItems) {
      if (item is Map) {
        final unit = _spatialUnitFromMap(Map<String, dynamic>.from(item));
        if (unit != null) units.add(unit);
      }
    }
    return units;
  }
}
