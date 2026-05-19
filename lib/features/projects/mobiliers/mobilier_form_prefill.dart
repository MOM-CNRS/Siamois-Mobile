import '../form/form_measurement_value.dart';
import '../form/project_form_models.dart';
import '../form/person_option.dart';
import '../form/recording_unit_option.dart';

/// Pré-remplit [ProjectFormState] depuis les champs API (`currentValue`).
abstract final class MobilierFormPrefill {
  static void applyFromApiFields(
    ProjectFormState state,
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldsRaw,
  ) {
    final valuesByFieldId = <int, dynamic>{};
    for (final entry in fieldsRaw.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final idRaw = map['fieldId'] ?? entry.key;
      int? fieldId;
      if (idRaw is int) {
        fieldId = idRaw;
      } else if (idRaw is num) {
        fieldId = idRaw.toInt();
      } else {
        fieldId = int.tryParse(idRaw?.toString() ?? '');
      }
      if (fieldId == null) continue;
      if (map.containsKey('currentValue')) {
        valuesByFieldId[fieldId] = map['currentValue'];
      }
    }

    for (final field in definition.fields) {
      final value = valuesByFieldId[field.fieldId];
      if (value == null) continue;
      _applyValue(state, field, value);
    }
  }

  static void _applyValue(
    ProjectFormState state,
    ProjectFormField field,
    dynamic value,
  ) {
    switch (field.normalizedType) {
      case ProjectAnswerType.text:
      case ProjectAnswerType.integer:
        final text = _asString(value);
        if (text != null) state.textValues[field.key] = text;
      case ProjectAnswerType.measurement:
        final measurement = FormMeasurementValue.fromDynamic(value);
        if (measurement != null) {
          state.measurementValues[field.key] = measurement;
        }
      case ProjectAnswerType.selectMultipleRecordingUnit:
        final units = RecordingUnitOption.listFromCurrentValue(value);
        if (units.isNotEmpty) {
          state.recordingUnitMultiValues[field.key] = units;
        }
      case ProjectAnswerType.selectOnePerson:
        final person = PersonOption.fromDynamic(value);
        if (person != null) {
          state.personSingleValues[field.key] = person;
        }
      case ProjectAnswerType.selectMultiplePerson:
        final people = PersonOption.listFromDynamic(value);
        if (people.isNotEmpty) {
          state.personMultiValues[field.key] = people;
        }
      case ProjectAnswerType.dateTime:
        final date = _parseDate(value);
        if (date != null) state.dateValues[field.key] = date;
      case ProjectAnswerType.selectOneFromFieldCode:
        final conceptId = _conceptId(value);
        if (conceptId != null) state.conceptValues[field.key] = conceptId;
      case ProjectAnswerType.selectOneSpatialUnit:
        final su = SpatialUnitOption.fromJson(value);
        if (su != null) state.spatialSingleValues[field.key] = su;
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        if (value is List) {
          final units = <SpatialUnitOption>[];
          for (final item in value) {
            final unit = SpatialUnitOption.fromJson(item);
            if (unit != null) units.add(unit);
          }
          if (units.isNotEmpty) {
            state.spatialMultiValues[field.key] = units;
          }
        } else {
          final su = SpatialUnitOption.fromJson(value);
          if (su != null) state.spatialMultiValues[field.key] = [su];
        }
      default:
        break;
    }
  }

  static String? _asString(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
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
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final id = map['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return int.tryParse(id?.toString() ?? '');
    }
    return int.tryParse(raw?.toString() ?? '');
  }
}
