import 'project_form_models.dart';

/// Ajoute les réponses personne dans `fieldAnswers`.
abstract final class FormPersonPayload {
  static void appendToFieldAnswers({
    required ProjectFormState state,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    for (final field in definition.fieldsInLayoutOrder) {
      switch (field.normalizedType) {
        case ProjectAnswerType.selectOnePerson:
          final person = state.personSingleValues[field.key];
          if (person != null) {
            fieldAnswers['${field.fieldId}'] = person.id;
          }
        case ProjectAnswerType.selectMultiplePerson:
          final people = state.personMultiValues[field.key] ?? const [];
          if (people.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] =
                people.map((p) => p.id).toList();
          }
        default:
          break;
      }
    }
  }
}
