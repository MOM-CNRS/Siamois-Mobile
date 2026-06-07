import 'project_form_models.dart';

/// Extrait les valeurs affichables d’un projet API pour chaque champ du formulaire.
class ProjectDetailMapper {
  ProjectDetailMapper(this._project);

  final Map<String, dynamic> _project;

  String? displayValue(ProjectFormField field) {
    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _fromBinding(binding, field);
      if (fromBinding != null && fromBinding.isNotEmpty) {
        return fromBinding;
      }
    }
    return _fromAnswerType(field);
  }

  String? _fromBinding(String binding, ProjectFormField field) {
    switch (binding) {
      case 'name':
        return _asString(_project['name']);
      case 'identifier':
        return _asString(_project['identifier']) ??
            _asString(_project['fullIdentifier']);
      case 'type':
        return _conceptDisplayLabel(_project['typeConcept']) ??
            _asString(_project['categorie']);
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
        if (field.fieldCode == 'SIAAU.TYPE' || field.valueBinding == 'type') {
          return _conceptDisplayLabel(_project['typeConcept']) ??
              _asString(_project['categorie']);
        }
        return null;
      case ProjectAnswerType.selectOneActionCode:
        return _asString(_project['codeOperationArcheologique']);
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

  String? _spatialContextDisplay() {
    final loc = _project['localisation'];
    if (loc is Map) {
      final precise = loc['localisationsPrecises'];
      if (precise is List && precise.isNotEmpty) {
        return precise.map((e) => e.toString()).join('\n');
      }
    }

    final rel = _project['spatialContext'];
    if (rel is Map) {
      final data = rel['data'];
      if (data is List && data.isNotEmpty) {
        final labels = <String>[];
        for (final item in data) {
          final label = _placeFromMap(item);
          if (label != null && label.isNotEmpty) {
            labels.add(label);
          }
        }
        if (labels.isNotEmpty) return labels.join('\n');
      }
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
    return _asString(raw['displayLabel']);
  }

  static String? _placeFromRelationship(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is Map) return _placeFromMap(data);
    return null;
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
