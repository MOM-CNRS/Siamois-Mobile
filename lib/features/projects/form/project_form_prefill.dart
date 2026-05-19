import 'project_form_models.dart';

/// Pré-remplit [ProjectFormState] depuis la réponse `GET /api/v1/projects/{id}`.
abstract final class ProjectFormPrefill {
  static void apply(
    ProjectFormState state,
    ProjectFormDefinition definition,
    Map<String, dynamic> project,
  ) {
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
          if (binding == 'type') {
            final typeId = _conceptId(project['typeConcept']);
            if (typeId != null) {
              state.conceptValues[field.key] = typeId;
            }
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
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

  static SpatialUnitOption? _spatialUnit(dynamic rel) {
    if (rel is! Map) return null;
    final data = rel['data'];
    if (data is Map) {
      return _spatialUnitFromMap(Map<String, dynamic>.from(data));
    }
    return _spatialUnitFromMap(Map<String, dynamic>.from(rel));
  }

  static SpatialUnitOption? _spatialUnitFromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    int? id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    }
    if (id == null) return null;

    final name = (map['name'] as String?)?.trim() ?? 'Lieu $id';
    return SpatialUnitOption(
      id: id,
      label: name,
      code: (map['code'] as String?)?.trim(),
    );
  }

  static List<SpatialUnitOption> _spatialContextUnits(
    Map<String, dynamic> project,
  ) {
    final rel = project['spatialContext'];
    if (rel is! Map) return const [];

    final data = rel['data'];
    if (data is! List) return const [];

    final units = <SpatialUnitOption>[];
    for (final item in data) {
      if (item is Map) {
        final unit = _spatialUnitFromMap(Map<String, dynamic>.from(item));
        if (unit != null) units.add(unit);
      }
    }
    return units;
  }
}
