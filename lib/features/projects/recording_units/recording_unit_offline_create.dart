import '../form/project_form_models.dart';
import '../project_detail_models.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_field_answers_merge.dart';
import 'recording_unit_local_id.dart';

/// Construit une UE locale (cache + file d’attente) avant envoi serveur.
abstract final class RecordingUnitOfflineCreate {
  static RecordingUnitMobileDetail buildDetail({
    required String listId,
    required ConceptOption type,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    final fields = <String, RecordingUnitFormFieldEntry>{};
    for (final field in definition.fields) {
      final answerKey = '${field.fieldId}';
      if (!fieldAnswers.containsKey(answerKey)) continue;
      fields[answerKey] = RecordingUnitFormFieldEntry(
        fieldId: field.fieldId,
        label: field.label,
        hint: field.hint,
        answerType: field.answerType,
        valueBinding: field.valueBinding,
        fieldCode: field.fieldCode,
        currentValue: fieldAnswers[answerKey],
      );
    }

    final displayCode = _displayCode(definition, fieldAnswers) ?? 'UE (hors ligne)';
    final identifier = _identifier(definition, fieldAnswers);

    final recordingUnit = <String, dynamic>{
      'resourceId': listId,
      'id': RecordingUnitLocalId.localIdFromListId(listId),
      'fullIdentifier': displayCode,
      if (identifier != null) 'identifier': identifier,
      'typeConceptId': type.id,
      'type': {
        'data': {
          'conceptId': type.id,
          'label': type.label,
          'displayLabel': type.label,
        },
      },
      '_pendingCreate': true,
    };

    final base = RecordingUnitMobileDetail(
      recordingUnit: recordingUnit,
      fields: fields,
    );

    return RecordingUnitFieldAnswersMerge.apply(
      detail: base,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
  }

  static RecordingUnitItem buildListItem({
    required RecordingUnitMobileDetail detail,
    required ConceptOption type,
  }) {
    return RecordingUnitItem.fromJson(detail.recordingUnit).copyWith(
      typeLabel: type.label,
    );
  }

  static String? _displayCode(
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldAnswers,
  ) {
    final identifier = _identifier(definition, fieldAnswers);
    if (identifier != null && identifier.isNotEmpty) return identifier;

    for (final field in definition.fields) {
      if (field.valueBinding != 'name') continue;
      final raw = fieldAnswers['${field.fieldId}'];
      final text = raw?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _identifier(
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldAnswers,
  ) {
    for (final field in definition.fields) {
      if (field.valueBinding != 'identifier') continue;
      final raw = fieldAnswers['${field.fieldId}'];
      final text = raw?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

extension _RecordingUnitItemCopy on RecordingUnitItem {
  RecordingUnitItem copyWith({
    String? typeLabel,
  }) {
    return RecordingUnitItem(
      id: id,
      displayCode: displayCode,
      identifier: identifier,
      typeLabel: typeLabel ?? this.typeLabel,
      placeLabel: placeLabel,
      openingDate: openingDate,
      closingDate: closingDate,
      matrixColor: matrixColor,
      specimenCount: specimenCount,
      stratigraphicCount: stratigraphicCount,
    );
  }
}
