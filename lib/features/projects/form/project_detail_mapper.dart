import '../vocabulary_models.dart';
import 'project_form_models.dart';

/// Extrait les valeurs affichables d’un projet API pour chaque champ du formulaire.
class ProjectDetailMapper {
  ProjectDetailMapper(
    this._project, {
    Map<String, List<ConceptOption>>? vocabByCode,
  }) : _vocabByCode = vocabByCode;

  final Map<String, dynamic> _project;
  final Map<String, List<ConceptOption>>? _vocabByCode;

  String? displayValue(ProjectFormField field) {
    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _fromBinding(binding, field);
      if (fromBinding != null && fromBinding.isNotEmpty) {
        return fromBinding;
      }
    }
    final fromType = _fromAnswerType(field);
    if (fromType != null && fromType.isNotEmpty) {
      return fromType;
    }
    return _fromFieldAnswers(field);
  }

  String? _fromBinding(String binding, ProjectFormField field) {
    switch (binding) {
      case 'name':
        return _asString(_project['name']);
      case 'identifier':
        return _asString(_project['identifier']) ??
            _asString(_project['fullIdentifier']);
      case 'type':
        return _categoryDisplay(field);
      case 'beginDate':
        return _formatDateTime(_project['beginDate']);
      case 'endDate':
        return _formatDateTime(_project['endDate']);
      case 'primaryActionCode':
        return _asString(_project['codeOperationArcheologique']);
      case 'mainLocation':
        return _placeFromRelationship(_project['mainLocation']) ??
            _localisationPrincipal();
      case 'spatialContext':
        return _spatialContextDisplay();
      default:
        return null;
    }
  }

  String? _fromAnswerType(ProjectFormField field) {
    switch (field.normalizedType) {
      case ProjectAnswerType.selectOneFromFieldCode:
        if (_isCategoryField(field)) {
          return _categoryDisplay(field);
        }
        return _conceptFieldDisplay(field);
      case ProjectAnswerType.selectOneActionCode:
        return _asString(_project['codeOperationArcheologique']) ??
            _fromFieldAnswers(field);
      case ProjectAnswerType.selectOneSpatialUnit:
        return _placeFromRelationship(_project['mainLocation']) ??
            _localisationPrincipal();
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        return _spatialContextDisplay();
      case ProjectAnswerType.dateTime:
        if (field.valueBinding == 'beginDate') {
          return _formatDateTime(_project['beginDate']);
        }
        if (field.valueBinding == 'endDate') {
          return _formatDateTime(_project['endDate']);
        }
        return null;
      case ProjectAnswerType.text:
        if (field.valueBinding == 'name') {
          return _asString(_project['name']);
        }
        if (field.valueBinding == 'identifier') {
          return _asString(_project['identifier']);
        }
        return null;
      default:
        return null;
    }
  }

  String? _fromFieldAnswers(ProjectFormField field) {
    final answers = _project['fieldAnswers'];
    if (answers is! Map) return null;
    final raw = answers['${field.fieldId}'];
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => e.toString()).join('\n');
    }
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _spatialContextDisplay() {
    final loc = _project['localisation'];
    if (loc is Map) {
      final precise = loc['localisationsPrecises'];
      if (precise is List && precise.isNotEmpty) {
        return precise.map((e) => e.toString()).join('\n');
      }
    }

    final rel = _project['spatialContext'];
    final List? data;
    if (rel is List) {
      data = rel;
    } else if (rel is Map) {
      final nested = rel['data'];
      data = nested is List ? nested : null;
    } else {
      data = null;
    }

    if (data != null && data.isNotEmpty) {
      final labels = <String>[];
      for (final item in data) {
        final label = _placeFromMap(item);
        if (label != null && label.isNotEmpty) {
          labels.add(label);
        }
      }
      if (labels.isNotEmpty) return labels.join('\n');
    }
    return null;
  }

  String? _localisationPrincipal() {
    final loc = _project['localisation'];
    if (loc is Map) {
      return _asString(loc['communeOuLocalisation']);
    }
    return null;
  }

  static bool _isCategoryField(ProjectFormField field) {
    if (field.valueBinding?.trim() == 'type') return true;
    final code = field.fieldCode?.trim().toUpperCase();
    return code == 'SIAAU.TYPE' || code == 'SIAAU_TYPE';
  }

  String? _categoryDisplay(ProjectFormField field) {
    final fromLabels = _conceptDisplayLabel(_project['typeConcept']) ??
        _conceptDisplayLabel(_project['type']) ??
        _asString(_project['categorie']);
    if (fromLabels != null) return fromLabels;

    final typeId = _parseInt(_project['typeConceptId']) ??
        _conceptId(_project['typeConcept']) ??
        _conceptId(_project['type']);
    if (typeId == null) return null;

    return _labelForConceptId(typeId, field);
  }

  String? _conceptFieldDisplay(ProjectFormField field) {
    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      final conceptKey =
          binding.endsWith('Concept') ? binding : '${binding}Concept';
      final fromConcept = _conceptDisplayLabel(_project[conceptKey]) ??
          _conceptDisplayLabel(_project[binding]);
      if (fromConcept != null) return fromConcept;

      final conceptId =
          _conceptId(_project[conceptKey]) ?? _conceptId(_project[binding]);
      if (conceptId != null) {
        return _labelForConceptId(conceptId, field);
      }
    }

    return _fromFieldAnswers(field);
  }

  String? _labelForConceptId(int conceptId, ProjectFormField field) {
    final vocab = _vocabByCode;
    if (vocab == null) return null;

    for (final option in _optionsForField(field, vocab)) {
      if (option.id == conceptId) return option.label;
    }

    final fallback = vocab['SIAAU.TYPE'] ?? const [];
    for (final option in fallback) {
      if (option.id == conceptId) return option.label;
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

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String headerTitle(Map<String, dynamic> project) {
    return _asString(project['name']) ?? 'Projet';
  }

  static String? headerSubtitle(Map<String, dynamic> project) {
    return _asString(project['fullIdentifier']) ??
        _asString(project['identifier']);
  }

  static int? recordingUnitCount(Map<String, dynamic> project) =>
      relationshipMetaCount(project, 'recordingUnitList');

  static int? documentCount(Map<String, dynamic> project) =>
      relationshipMetaCount(project, 'documentList') ??
      relationshipMetaCount(project, 'documents');

  static int? relationshipMetaCount(
    Map<String, dynamic> project,
    String relationshipKey,
  ) {
    final rel = project[relationshipKey];
    if (rel is! Map) return null;
    final meta = rel['meta'];
    if (meta is! Map) return null;
    final count = meta['count'];
    if (count is int) return count;
    if (count is num) return count.toInt();
    return null;
  }

  static String? _conceptDisplayLabel(dynamic raw) {
    if (raw is! Map) return null;
    final direct = _asString(raw['displayLabel']) ?? _asString(raw['label']);
    if (direct != null) return direct;
    final data = raw['data'];
    if (data is Map) {
      return _asString(data['displayLabel']) ??
          _asString(data['label']) ??
          _asString(data['name']);
    }
    return null;
  }

  static String? _placeFromRelationship(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is Map) return _placeFromMap(data);
    // PlaceLightResource plat (GET /projects/{id})
    return _placeFromMap(raw);
  }

  static String? _placeFromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = _asString(map['name']);
    final code = _asString(map['code']);
    if (name != null && code != null && name != code) {
      return '$name ($code)';
    }
    return name ?? code;
  }

  static String? _formatDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final d = '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
      final hasTime =
          dt.hour != 0 || dt.minute != 0 || dt.second != 0 || dt.millisecond != 0;
      if (hasTime) {
        return '$d ${_two(dt.hour)}:${_two(dt.minute)}';
      }
      return d;
    } catch (_) {
      return raw.toString();
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String? _asString(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
