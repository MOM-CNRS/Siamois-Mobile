import 'package:flutter/material.dart';

import 'form_measurement_value.dart';
import 'project_form_models.dart';

/// Contrôleurs texte pour les champs mesure d’un formulaire.
class FormMeasurementControllers {
  final Map<String, TextEditingController> numeric = {};
  final Map<String, TextEditingController> comment = {};

  void dispose() {
    for (final c in numeric.values) {
      c.dispose();
    }
    for (final c in comment.values) {
      c.dispose();
    }
    numeric.clear();
    comment.clear();
  }

  void ensure(
    ProjectFormField field, {
    FormMeasurementValue? initial,
  }) {
    numeric.putIfAbsent(
      field.key,
      () => TextEditingController(
        text: initial?.numericValue?.toString() ?? '',
      ),
    );
    comment.putIfAbsent(
      field.key,
      () => TextEditingController(text: initial?.comment ?? ''),
    );
  }

  void syncTo(ProjectFormState state, ProjectFormDefinition definition) {
    for (final field in definition.fields) {
      if (!field.isMeasurementInput) continue;
      final n = FormMeasurementValue.parseDouble(numeric[field.key]?.text);
      final c = comment[field.key]?.text.trim() ?? '';
      if (n == null && c.isEmpty) {
        state.measurementValues.remove(field.key);
        continue;
      }
      state.measurementValues[field.key] = FormMeasurementValue(
        numericValue: n,
        comment: c,
        unitId: field.defaultUnitId,
        unitSymbol: field.unitSymbol,
      );
    }
  }
}

/// Ajoute les réponses `DECIMAL` et `BOOLEAN` dans un map `fieldAnswers`.
abstract final class FormScalarPayload {
  static void appendToFieldAnswers({
    required ProjectFormState state,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    for (final field in definition.fieldsInLayoutOrder) {
      if (field.isDecimalInput) {
        final raw = state.text(field.key)?.trim() ?? '';
        if (raw.isEmpty) continue;
        final n = FormMeasurementValue.parseDouble(raw);
        if (n == null) {
          throw FormatException('« ${field.label} » doit être un nombre.');
        }
        fieldAnswers['${field.fieldId}'] = n;
      } else if (field.isBooleanInput) {
        final value = state.boolValues[field.key];
        if (value != null) fieldAnswers['${field.fieldId}'] = value;
      }
    }
  }

  /// Valeur `BOOLEAN` lue dans une réponse API (bool, ou chaîne « true »).
  static bool? parseBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is Map) return parseBool(raw['value']);
    return switch (raw?.toString().trim().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }
}

/// Ajoute les réponses mesure dans un map `fieldAnswers`.
abstract final class FormMeasurementPayload {
  static void appendToFieldAnswers({
    required ProjectFormState state,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
    bool validateRequired = false,
  }) {
    for (final field in definition.fieldsInLayoutOrder) {
      if (!field.isMeasurementInput) continue;
      final value = state.measurementValues[field.key];
      if (value == null || value.isEmpty) {
        if (validateRequired && field.isRequired) {
          throw FormatException('« ${field.label} » est obligatoire.');
        }
        continue;
      }
      if (value.numericValue == null) {
        if (validateRequired || value.comment.trim().isNotEmpty) {
          throw FormatException(
            '« ${field.label} » : la taille doit être un nombre.',
          );
        }
        continue;
      }
      fieldAnswers['${field.fieldId}'] = value.toFieldAnswerJson(
        defaultUnitId: field.defaultUnitId,
        unitSymbol: field.unitSymbol,
      );
    }
  }
}
