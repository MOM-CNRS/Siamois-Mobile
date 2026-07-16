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

      final withoutServerId = selected
          .where((e) => e.serverRecordingUnitId == null)
          .toList(growable: false);
      if (withoutServerId.isNotEmpty) {
        final labels = withoutServerId.map((e) => e.label).join(', ');
        throw FormatException(
          'Impossible de lier « ${field.label} » : '
          'l’UE $labels n’a pas encore d’identifiant serveur '
          '(synchronisez d’abord les UE créées hors ligne).',
        );
      }

      fieldAnswers['${field.fieldId}'] =
          selected.map((e) => e.toFieldAnswerJson()).toList();
    }
  }
}
