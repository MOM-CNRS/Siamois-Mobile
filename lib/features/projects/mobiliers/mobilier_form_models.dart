import '../form/form_measurement_form.dart';
import '../form/form_person_payload.dart';
import '../form/form_recording_unit_multi.dart';
import '../form/project_form_models.dart';

/// Corps de requête pour `POST /api/v1/mobiliers`.
class MobilierCreateRequest {
  const MobilierCreateRequest({
    required this.recordingUnitId,
    required this.specimenTypeConceptId,
    this.fieldAnswers = const {},
  });

  final String recordingUnitId;
  final int specimenTypeConceptId;
  final Map<String, dynamic> fieldAnswers;
}

/// Construit les payloads mobilier à partir de [ProjectFormState].
extension MobilierFormPayload on ProjectFormState {
  MobilierCreateRequest buildMobilierCreateRequest({
    required String recordingUnitId,
    required ProjectFormDefinition definition,
  }) {
    final parsed = _parseMobilierFields(definition);
    if (parsed.typeConceptId == null) {
      throw const FormatException('Le type de mobilier est obligatoire.');
    }
    return MobilierCreateRequest(
      recordingUnitId: recordingUnitId,
      specimenTypeConceptId: parsed.typeConceptId!,
      fieldAnswers: parsed.fieldAnswers,
    );
  }

  Map<String, dynamic> buildMobilierPatchFieldAnswers(
    ProjectFormDefinition definition,
  ) {
    return _parseMobilierFields(definition).fieldAnswers;
  }

  _MobilierParsedFields _parseMobilierFields(ProjectFormDefinition definition) {
    int? typeConceptId;
    final fieldAnswers = <String, dynamic>{};

    for (final field in definition.fieldsInLayoutOrder) {
      switch (field.normalizedType) {
        case ProjectAnswerType.text:
          final v = text(field.key)?.trim() ?? '';
          if (field.valueBinding == 'type') {
            break;
          }
          if (v.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] = v;
          }
        case ProjectAnswerType.integer:
          final raw = text(field.key)?.trim() ?? '';
          if (field.valueBinding == 'type') {
            break;
          }
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
            if (field.valueBinding == 'type') {
              break;
            }
            fieldAnswers['${field.fieldId}'] = d.toUtc().toIso8601String();
          }
        case ProjectAnswerType.selectOneFromFieldCode:
          final conceptId = conceptValues[field.key];
          if (conceptId != null) {
            if (field.valueBinding == 'type') {
              typeConceptId = conceptId;
            } else {
              fieldAnswers['${field.fieldId}'] = conceptId;
            }
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

    return _MobilierParsedFields(
      typeConceptId: typeConceptId,
      fieldAnswers: fieldAnswers,
    );
  }
}

class _MobilierParsedFields {
  const _MobilierParsedFields({
    this.typeConceptId,
    required this.fieldAnswers,
  });

  final int? typeConceptId;
  final Map<String, dynamic> fieldAnswers;
}
