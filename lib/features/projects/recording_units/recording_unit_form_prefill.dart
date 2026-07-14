import '../form/person_option.dart';
import '../form/project_form_models.dart';
import '../form/recording_unit_option.dart';
import '../mobiliers/mobilier_form_prefill.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_hierarchy.dart';

/// Pré-remplit [ProjectFormState] pour l’édition d’une UE.
abstract final class RecordingUnitFormPrefill {
  static void applyFromDetail(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<int, PersonOption>? directoryById,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final fieldsRaw = <String, dynamic>{};
    for (final entry in detail.fields.entries) {
      fieldsRaw['${entry.value.fieldId}'] = {
        'fieldId': entry.value.fieldId,
        'currentValue': entry.value.currentValue,
      };
    }

    MobilierFormPrefill.applyFromApiFields(
      state,
      definition,
      fieldsRaw,
      directoryById: directoryById,
    );

    _applyRecordingUnitBindings(
      state,
      definition,
      detail,
      directoryById: directoryById,
      vocabByCode: vocabByCode,
    );
  }

  /// Complète les champs depuis `recordingUnit` (priorité aux liaisons système).
  static void _applyRecordingUnitBindings(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<int, PersonOption>? directoryById,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final ru = detail.recordingUnit;
    final fields = detail.fields;

    for (final field in definition.fields) {
      if (field.isRecordingUnitTypeField) continue;

      final entry = fields['${field.fieldId}'];
      final binding = field.valueBinding?.trim();

      switch (field.normalizedType) {
        case ProjectAnswerType.text:
        case ProjectAnswerType.integer:
          final text = _textValue(
            state: state,
            field: field,
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (text != null) {
            state.textValues[field.key] = text;
          }
        case ProjectAnswerType.dateTime:
          if (state.dateValues[field.key] != null) continue;
          final date = _dateValue(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (date != null) state.dateValues[field.key] = date;
        case ProjectAnswerType.selectOneFromFieldCode:
          if (state.conceptValues[field.key] != null) continue;
          final conceptId = _conceptValue(
            field: field,
            binding: binding,
            recordingUnit: ru,
            entry: entry,
            vocabByCode: vocabByCode,
          );
          if (conceptId != null) state.conceptValues[field.key] = conceptId;
        case ProjectAnswerType.selectOneSpatialUnit:
          if (state.spatialSingleValues[field.key] != null) continue;
          final place = _spatialSingle(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (place != null) state.spatialSingleValues[field.key] = place;
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          final existing = state.spatialMultiValues[field.key];
          if (existing != null && existing.isNotEmpty) continue;
          final places = _spatialMulti(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (places.isNotEmpty) state.spatialMultiValues[field.key] = places;
        case ProjectAnswerType.selectOnePerson:
          if (state.person(field.key) != null) continue;
          final person = PersonOption.resolve(
            _rawValue(binding: binding, recordingUnit: ru, entry: entry),
            directoryById: directoryById,
          );
          if (person != null) state.personSingleValues[field.key] = person;
        case ProjectAnswerType.selectMultiplePerson:
          if (state.persons(field.key).isNotEmpty) continue;
          final people = PersonOption.listFromDynamic(
            _rawValue(binding: binding, recordingUnit: ru, entry: entry),
          )
              .map((p) => PersonOption.resolve(p, directoryById: directoryById))
              .whereType<PersonOption>()
              .toList();
          if (people.isNotEmpty) state.personMultiValues[field.key] = people;
        case ProjectAnswerType.selectMultipleRecordingUnit:
          if (state.recordingUnits(field.key).isNotEmpty) continue;
          if (!RecordingUnitHierarchy.isHierarchyRelationField(
            label: field.label,
            valueBinding: field.valueBinding,
            fieldCode: field.fieldCode,
            answerType: field.answerType,
            hint: field.hint,
          )) {
            continue;
          }
          final units = RecordingUnitOption.listFromCurrentValue(
            _rawValue(binding: binding, recordingUnit: ru, entry: entry),
          );
          if (units.isNotEmpty) {
            state.recordingUnitMultiValues[field.key] = units;
          }
        default:
          break;
      }
    }
  }

  static String? _textValue({
    required ProjectFormState state,
    required ProjectFormField field,
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    if (binding == 'identifier') {
      final shortId = _string(recordingUnit['identifier']);
      if (shortId != null) return shortId;
      return _string(recordingUnit['fullIdentifier']) ??
          (_hasText(state, field) ? state.textValues[field.key] : null) ??
          _string(entry?.currentValue);
    }

    if (_hasText(state, field)) return null;

    if (binding == 'name') {
      return _string(recordingUnit['name']) ?? _string(entry?.currentValue);
    }

    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _string(recordingUnit[binding]);
      if (fromBinding != null) return fromBinding;
    }

    return _string(entry?.currentValue);
  }

  static bool _hasText(ProjectFormState state, ProjectFormField field) {
    final value = state.textValues[field.key];
    return value != null && value.trim().isNotEmpty;
  }

  static DateTime? _dateValue({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'openingDate') {
      raw = recordingUnit['openingDate'];
    } else if (binding == 'closingDate') {
      raw = recordingUnit['closingDate'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;
    return _parseDate(raw);
  }

  static int? _conceptValue({
    required ProjectFormField field,
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    if (binding == 'type' || field.isRecordingUnitTypeField) {
      final direct = _parseInt(recordingUnit['typeConceptId']);
      if (direct != null) return direct;
      final fromType = _conceptId(recordingUnit['type']);
      if (fromType != null) return fromType;
    }

    dynamic raw = binding != null ? recordingUnit[binding] : null;
    raw ??= entry?.currentValue;
    final id = _conceptId(raw);
    if (id != null) return id;

    final label = _conceptLabel(raw);
    if (label != null && vocabByCode != null) {
      return _matchConceptByLabel(label, field, vocabByCode);
    }
    return null;
  }

  static SpatialUnitOption? _spatialSingle({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'place') {
      raw = recordingUnit['place'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;
    return SpatialUnitOption.fromJson(raw);
  }

  static List<SpatialUnitOption> _spatialMulti({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'spatialContext') {
      raw = recordingUnit['spatialContext'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;

    if (raw is List) {
      return raw
          .map(SpatialUnitOption.fromJson)
          .whereType<SpatialUnitOption>()
          .toList();
    }

    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return data
            .map(SpatialUnitOption.fromJson)
            .whereType<SpatialUnitOption>()
            .toList();
      }
    }

    final single = SpatialUnitOption.fromJson(raw);
    return single != null ? [single] : const [];
  }

  static dynamic _rawValue({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = recordingUnit[binding];
      if (fromBinding != null) return fromBinding;
    }
    return entry?.currentValue;
  }

  static int? _matchConceptByLabel(
    String label,
    ProjectFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final code = field.fieldCode?.trim();
    final options = (code != null && code.isNotEmpty
            ? vocabByCode[code]
            : null) ??
        vocabByCode['SIARU.TYPE'] ??
        const <ConceptOption>[];

    for (final option in options) {
      if (option.label.trim().toLowerCase() == normalized) return option.id;
    }
    return null;
  }

  static String? _conceptLabel(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return _string(map['displayLabel']) ?? _string(map['label']);
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

    final data = map['data'];
    if (data is Map) return _conceptId(data);
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
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
}
