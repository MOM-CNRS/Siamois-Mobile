import 'project_form_models.dart';
import 'recording_unit_option.dart';

/// Ajoute les réponses `SELECT_MULTIPLE_RECORDING_UNIT` dans `fieldAnswers`.
abstract final class FormRecordingUnitMultiPayload {
  static void appendToFieldAnswers({
    required ProjectFormState state,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    for (final field in definition.fieldsInLayoutOrder) {
      if (!field.isRecordingUnitMultiInput) continue;
      final selected = state.recordingUnitMultiValues[field.key] ?? const [];
      if (selected.isEmpty) continue;
      fieldAnswers['${field.fieldId}'] =
          selected.map((e) => e.toFieldAnswerJson()).toList();
    }
  }
}
