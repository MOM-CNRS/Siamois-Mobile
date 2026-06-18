import '../form/project_form_models.dart';
import 'recording_unit_detail_models.dart';

/// Fusionne les réponses soumises dans le détail UE (cache / affichage).
abstract final class RecordingUnitFieldAnswersMerge {
  static RecordingUnitMobileDetail apply({
    required RecordingUnitMobileDetail detail,
    required Map<String, dynamic> fieldAnswers,
    ProjectFormDefinition? definition,
  }) {
    if (fieldAnswers.isEmpty) return detail;

    final ru = Map<String, dynamic>.from(detail.recordingUnit);
    final fields = Map<String, RecordingUnitFormFieldEntry>.from(detail.fields);

    if (definition != null) {
      for (final field in definition.fields) {
        _mergeField(
          fields: fields,
          recordingUnit: ru,
          fieldId: field.fieldId,
          label: field.label,
          hint: field.hint,
          answerType: field.answerType,
          valueBinding: field.valueBinding,
          fieldCode: field.fieldCode,
          answer: fieldAnswers['${field.fieldId}'],
        );
      }
    }

    for (final entry in fieldAnswers.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final existing = fields[key];
      _mergeField(
        fields: fields,
        recordingUnit: ru,
        fieldId: existing?.fieldId ?? int.tryParse(key) ?? 0,
        label: existing?.label,
        hint: existing?.hint,
        answerType: existing?.answerType,
        valueBinding: existing?.valueBinding,
        fieldCode: existing?.fieldCode,
        answer: entry.value,
      );
    }

    return RecordingUnitMobileDetail(
      recordingUnit: ru,
      formName: detail.formName,
      layoutJson: detail.layoutJson,
      fields: fields,
    );
  }

  static void _mergeField({
    required Map<String, RecordingUnitFormFieldEntry> fields,
    required Map<String, dynamic> recordingUnit,
    required int fieldId,
    String? label,
    String? hint,
    String? answerType,
    String? valueBinding,
    String? fieldCode,
    required dynamic answer,
  }) {
    if (fieldId <= 0 || answer == null) return;

    final key = '$fieldId';
    final existing = fields[key];
    fields[key] = RecordingUnitFormFieldEntry(
      fieldId: fieldId,
      label: label ?? existing?.label ?? 'Champ',
      hint: hint ?? existing?.hint,
      answerType: answerType ?? existing?.answerType,
      valueBinding: valueBinding ?? existing?.valueBinding,
      fieldCode: fieldCode ?? existing?.fieldCode,
      currentValue: answer,
    );

    final binding = (valueBinding ?? existing?.valueBinding)?.trim();
    if (binding != null && binding.isNotEmpty) {
      recordingUnit[binding] = answer;
    }
  }
}
