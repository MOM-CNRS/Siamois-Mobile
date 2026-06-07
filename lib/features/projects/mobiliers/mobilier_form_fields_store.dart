import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../form/project_form_models.dart';

/// Persistance locale des champs formulaire mobilier (dont UE multiples).
class MobilierFormFieldsStore {
  MobilierFormFieldsStore(this._db);

  final AppDatabase _db;

  Future<void> saveFromApiFields({
    required String mobilierId,
    required String recordingUnitId,
    required Map<String, dynamic> fieldsRaw,
  }) async {
    if (mobilierId.trim().isEmpty) return;
    await _db.replaceMobilierDetailFields(
      resourceId: mobilierId.trim(),
      uniteEnregistrementId: recordingUnitId.trim(),
      fieldsRaw: fieldsRaw,
    );
  }

  Future<void> saveFromFieldAnswers({
    required String mobilierId,
    required String recordingUnitId,
    required Map<String, dynamic> fieldsRaw,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) async {
    final merged = mergeFieldAnswersIntoFieldsRaw(
      fieldsRaw: fieldsRaw,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
    await saveFromApiFields(
      mobilierId: mobilierId,
      recordingUnitId: recordingUnitId,
      fieldsRaw: merged,
    );
  }

  Future<Map<String, dynamic>?> loadFieldsRaw(String mobilierId) async {
    return _db.mobilierDetailFieldsRaw(mobilierId.trim());
  }

  /// Fusionne les réponses soumises dans la structure `fields` de l’API.
  static Map<String, dynamic> mergeFieldAnswersIntoFieldsRaw({
    required Map<String, dynamic> fieldsRaw,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    final out = Map<String, dynamic>.from(fieldsRaw);
    for (final field in definition.fields) {
      final answer = fieldAnswers['${field.fieldId}'];
      if (answer == null) continue;
      final entryKey = '${field.fieldId}';
      final existing = out[entryKey];
      if (existing is Map) {
        out[entryKey] = {
          ...Map<String, dynamic>.from(existing),
          'fieldId': field.fieldId,
          'currentValue': answer,
        };
      } else {
        out[entryKey] = {
          'fieldId': field.fieldId,
          'label': field.label,
          if (field.hint != null) 'hint': field.hint,
          'answerType': field.answerType,
          'currentValue': answer,
        };
      }
    }
    return out;
  }

  static String encodeFieldsRaw(Map<String, dynamic> fieldsRaw) =>
      jsonEncode(fieldsRaw);
}
