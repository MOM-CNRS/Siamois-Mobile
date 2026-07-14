import '../../core/database/app_database.dart';
import 'vocabulary_models.dart';
import 'form/project_form_models.dart';
import 'project_models.dart';

/// Construit un projet local (cache + file d’attente) avant envoi serveur.
abstract final class ProjectOfflineCreate {
  static ProjectSummary buildSummary({
    required String listId,
    required ProjectCreatePayload payload,
  }) {
    return ProjectSummary(
      id: listId,
      name: payload.name,
      identifier: payload.identifier,
      fullIdentifier: payload.identifier,
      recordingUnitCount: 0,
    );
  }

  static Map<String, dynamic> buildDetail({
    required String listId,
    required ProjectCreatePayload payload,
    required ProjectFormDefinition definition,
    required ProjectFormState formState,
    required Map<String, List<ConceptOption>> vocabByCode,
  }) {
    final detail = <String, dynamic>{
      'id': listId,
      'name': payload.name,
      'identifier': payload.identifier,
      'fullIdentifier': payload.identifier,
      'typeConceptId': payload.typeConceptId,
      if (payload.beginDate != null)
        'beginDate': payload.beginDate!.toUtc().toIso8601String(),
      if (payload.endDate != null)
        'endDate': payload.endDate!.toUtc().toIso8601String(),
      if (payload.spatialContextSpatialUnitIds.isNotEmpty)
        'spatialContextSpatialUnitIds': payload.spatialContextSpatialUnitIds,
      if (payload.fieldAnswers.isNotEmpty) 'fieldAnswers': payload.fieldAnswers,
      'recordingUnitList': {
        'meta': {'count': 0},
      },
      '_pendingCreate': true,
    };

    final typeLabel = _typeLabel(
      definition: definition,
      formState: formState,
      vocabByCode: vocabByCode,
      typeConceptId: payload.typeConceptId,
    );
    if (typeLabel != null) {
      detail['typeConcept'] = {
        'conceptId': payload.typeConceptId,
        'displayLabel': typeLabel,
      };
      detail['categorie'] = typeLabel;
    }

    for (final field in definition.fields) {
      final binding = field.valueBinding?.trim();
      if (binding == null || binding.isEmpty) continue;

      switch (binding) {
        case 'primaryActionCode':
          final actionCode = _primaryActionCode(formState, field);
          if (actionCode != null) {
            detail['codeOperationArcheologique'] = actionCode;
          }
        case 'mainLocation':
          final place = formState.spatialSingleValues[field.key];
          if (place != null) {
            detail['mainLocation'] = _placeRelationship(place);
          }
        case 'spatialContext':
          final places = formState.spatialMultiValues[field.key] ?? const [];
          if (places.isNotEmpty) {
            detail['spatialContext'] = {
              'data': places.map(_placeMap).toList(),
            };
          }
        default:
          break;
      }
    }

    return detail;
  }

  /// Complète un détail projet local déjà en cache (projets créés avant enrichissement).
  static Future<Map<String, dynamic>> enrichPendingDetail({
    required Map<String, dynamic> detail,
    required ProjectFormDefinition definition,
    required Map<String, List<ConceptOption>> vocabByCode,
    required AppDatabase db,
    required int organisationId,
  }) async {
    if (detail['_pendingCreate'] != true) return detail;

    final map = Map<String, dynamic>.from(detail);

    _ensureTypeConcept(map, definition, vocabByCode);

    for (final field in definition.fields) {
      final binding = field.valueBinding?.trim();
      if (binding == null || binding.isEmpty) continue;

      switch (binding) {
        case 'identifier':
          if (_string(map['identifier']) == null) {
            final value = _valueFromFieldAnswers(map, field);
            if (value != null) {
              map['identifier'] = value;
              map['fullIdentifier'] ??= value;
            }
          }
        case 'primaryActionCode':
          if (_string(map['codeOperationArcheologique']) == null) {
            final code = _valueFromFieldAnswers(map, field);
            if (code != null) {
              map['codeOperationArcheologique'] = code;
            }
          }
        case 'mainLocation':
          if (map['mainLocation'] == null) {
            final placeId = _placeIdFromFieldAnswers(map, field);
            if (placeId != null) {
              final rel = await _placeRelationshipFromCache(
                db: db,
                organisationId: organisationId,
                placeId: placeId,
              );
              if (rel != null) map['mainLocation'] = rel;
            }
          }
        case 'spatialContext':
          if (map['spatialContext'] == null) {
            final ids = _spatialContextIds(map, field);
            if (ids.isNotEmpty) {
              final places = <Map<String, dynamic>>[];
              for (final placeId in ids) {
                final rel = await _placeRelationshipFromCache(
                  db: db,
                  organisationId: organisationId,
                  placeId: placeId,
                );
                final data = rel?['data'];
                if (data is Map) {
                  places.add(Map<String, dynamic>.from(data));
                }
              }
              if (places.isNotEmpty) {
                map['spatialContext'] = {'data': places};
              }
            }
          }
        default:
          break;
      }
    }

    return map;
  }

  static Map<String, dynamic> detailFromSummary(ProjectSummary summary) {
    return {
      'id': summary.id,
      'name': summary.name,
      'identifier': summary.identifier,
      'fullIdentifier': summary.fullIdentifier ?? summary.identifier,
      if (summary.recordingUnitCount != null)
        'recordingUnitList': {
          'meta': {'count': summary.recordingUnitCount},
        },
    };
  }

  static String? _typeLabel({
    required ProjectFormDefinition definition,
    required ProjectFormState formState,
    required Map<String, List<ConceptOption>> vocabByCode,
    required int typeConceptId,
  }) {
    for (final field in definition.fields) {
      if (field.valueBinding != 'type' &&
          field.fieldCode?.trim().toUpperCase() != 'SIAAU.TYPE') {
        continue;
      }
      for (final option in formState.conceptsForField(field, vocabByCode)) {
        if (option.id == typeConceptId) return option.label;
      }
    }

    for (final options in vocabByCode.values) {
      for (final option in options) {
        if (option.id == typeConceptId) return option.label;
      }
    }
    return null;
  }

  static void _ensureTypeConcept(
    Map<String, dynamic> map,
    ProjectFormDefinition definition,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    if (_conceptDisplayLabel(map['typeConcept']) != null) return;

    final legacyType = map['type'];
    if (legacyType is Map) {
      final data = legacyType['data'];
      if (data is Map) {
        final label = _string(data['displayLabel']) ?? _string(data['label']);
        final conceptId = _parseInt(data['conceptId']) ?? _parseInt(map['typeConceptId']);
        if (label != null) {
          map['typeConcept'] = {
            if (conceptId != null) 'conceptId': conceptId,
            'displayLabel': label,
          };
          map['categorie'] ??= label;
          return;
        }
      }
    }

    final typeId = _parseInt(map['typeConceptId']);
    if (typeId == null) return;

    for (final field in definition.fields) {
      if (field.valueBinding != 'type' &&
          field.fieldCode?.trim().toUpperCase() != 'SIAAU.TYPE') {
        continue;
      }
      for (final option in vocabByCode[field.fieldCode ?? ''] ?? const []) {
        if (option.id == typeId) {
          map['typeConcept'] = {
            'conceptId': typeId,
            'displayLabel': option.label,
          };
          map['categorie'] ??= option.label;
          return;
        }
      }
    }

    final fallback = vocabByCode['SIAAU.TYPE'] ?? const [];
    for (final option in fallback) {
      if (option.id == typeId) {
        map['typeConcept'] = {
          'conceptId': typeId,
          'displayLabel': option.label,
        };
        map['categorie'] ??= option.label;
        return;
      }
    }
  }

  static String? _primaryActionCode(
    ProjectFormState formState,
    ProjectFormField field,
  ) {
    final text = formState.text(field.key)?.trim();
    if (text != null && text.isNotEmpty) return text;

    final place = formState.spatialSingleValues[field.key];
    if (place != null) return place.display;

    return null;
  }

  static String? _valueFromFieldAnswers(
    Map<String, dynamic> map,
    ProjectFormField field,
  ) {
    final answers = map['fieldAnswers'];
    if (answers is! Map) return null;
    final raw = answers['${field.fieldId}'];
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _placeIdFromFieldAnswers(
    Map<String, dynamic> map,
    ProjectFormField field,
  ) {
    final answers = map['fieldAnswers'];
    if (answers is! Map) return null;
    return _parseInt(answers['${field.fieldId}']);
  }

  static List<int> _spatialContextIds(
    Map<String, dynamic> map,
    ProjectFormField field,
  ) {
    final fromTop = map['spatialContextSpatialUnitIds'];
    if (fromTop is List && fromTop.isNotEmpty) {
      return fromTop.map(_parseInt).whereType<int>().toList();
    }

    final answers = map['fieldAnswers'];
    if (answers is! Map) return const [];

    final raw = answers['${field.fieldId}'];
    if (raw is List) {
      return raw.map(_parseInt).whereType<int>().toList();
    }
    final single = _parseInt(raw);
    if (single != null) return [single];
    return const [];
  }

  static Future<Map<String, dynamic>?> _placeRelationshipFromCache({
    required AppDatabase db,
    required int organisationId,
    required int placeId,
  }) async {
    final row = await db.cachedPlaceRow(
      organisationId: organisationId,
      placeId: placeId,
    );
    if (row == null) return null;
    return {
      'data': {
        'id': row.placeId,
        'name': row.name,
        if (row.code != null && row.code!.isNotEmpty) 'code': row.code,
      },
    };
  }

  static Map<String, dynamic> _placeRelationship(SpatialUnitOption place) {
    return {'data': _placeMap(place)};
  }

  static Map<String, dynamic> _placeMap(SpatialUnitOption place) {
    return {
      'id': place.id,
      'name': place.label,
      if (place.code != null && place.code!.isNotEmpty) 'code': place.code,
    };
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
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }
}
