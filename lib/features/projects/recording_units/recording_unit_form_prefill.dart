import '../form/project_form_models.dart';
import '../mobiliers/mobilier_form_prefill.dart';

/// Pré-remplit [ProjectFormState] depuis les champs API (`currentValue`).
abstract final class RecordingUnitFormPrefill {
  static void applyFromApiFields(
    ProjectFormState state,
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldsRaw,
  ) {
    MobilierFormPrefill.applyFromApiFields(state, definition, fieldsRaw);
  }
}
