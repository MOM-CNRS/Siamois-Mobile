import '../form/form_measurement_form.dart';
import '../form/form_person_payload.dart';
import '../form/form_recording_unit_multi.dart';
import '../form/project_form_models.dart';

/// Construit les `fieldAnswers` pour création / modification d’UE.
extension RecordingUnitFormPayload on ProjectFormState {
  Map<String, dynamic> buildRecordingUnitFieldAnswers(
    ProjectFormDefinition definition,
  ) {
    final fieldAnswers = <String, dynamic>{};

    for (final field in definition.fieldsInLayoutOrder) {
      if (field.isRecordingUnitTypeField) continue;

      switch (field.normalizedType) {
        case ProjectAnswerType.text:
          final v = text(field.key)?.trim() ?? '';
          if (v.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] = v;
          }
        case ProjectAnswerType.integer:
          final raw = text(field.key)?.trim() ?? '';
          if (raw.isNotEmpty) {
            final n = int.tryParse(raw);
            if (n == null) {
              throw FormatException(
                '« ${field.label} » doit être un nombre entier.',
              );
            }
            fieldAnswers['${field.fieldId}'] = n;
          }
        case ProjectAnswerType.dateTime:
          final d = dateValues[field.key];
          if (d != null) {
            fieldAnswers['${field.fieldId}'] = d.toUtc().toIso8601String();
          }
        case ProjectAnswerType.selectOneFromFieldCode:
          final conceptId = conceptValues[field.key];
          if (conceptId != null) {
            fieldAnswers['${field.fieldId}'] = conceptId;
          }
        case ProjectAnswerType.selectMultiple:
          final conceptIds = conceptMulti(field.key);
          if (conceptIds.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] = conceptIds;
          }
        case ProjectAnswerType.selectOneSpatialUnit:
          final su = spatialSingleValues[field.key];
          if (su != null) {
            fieldAnswers['${field.fieldId}'] = su.id;
          }
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          final list = spatialMultiValues[field.key] ?? const [];
          if (list.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] =
                list.map((e) => e.id).toList();
          }
        default:
          break;
      }
    }

    FormMeasurementPayload.appendToFieldAnswers(
      state: this,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
    FormRecordingUnitMultiPayload.appendToFieldAnswers(
      state: this,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
    FormPersonPayload.appendToFieldAnswers(
      state: this,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );

    return fieldAnswers;
  }
}

class RecordingUnitFormLoadResult {
  const RecordingUnitFormLoadResult({
    required this.definition,
    this.fieldsRaw = const {},
  });

  final ProjectFormDefinition definition;
  final Map<String, dynamic> fieldsRaw;
}
